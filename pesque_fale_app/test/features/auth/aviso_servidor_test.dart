import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pesque_fale_app/core/servidor/servidor_status_provider.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/presentation/cadastro/cadastro_page.dart';
import 'package:pesque_fale_app/features/auth/presentation/login/login_page.dart';
import 'package:pesque_fale_app/features/auth/presentation/widgets/aviso_servidor.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';

import '../../core/servidor/support/fake_health.dart';

/// Conta as chamadas de login e cadastro.
class _AuthRepository implements AuthRepository {
  int logins = 0;
  int cadastros = 0;

  AuthResult _resultado(String email) => AuthResult(
    accessToken: 'token',
    usuario: Usuario(
      id: 'user-1',
      nome: 'Ana',
      email: email,
      onboardingConcluido: true,
    ),
  );

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async {
    logins++;
    return _resultado(email);
  }

  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async {
    cadastros++;
    return _resultado(email);
  }

  @override
  Future<void> logout() async {}
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late FakeHealth health;
  late _AuthRepository auth;

  setUp(() {
    health = FakeHealth();
    auth = _AuthRepository();
  });

  /// O provider nasce aqui, como no main.dart: a checagem começa na montagem.
  Future<ServidorStatusProvider> montar(
    WidgetTester tester, {
    String rota = '/login',
    ThemeData? tema,
    ServidorStatusProvider? servidor,
  }) async {
    final provider = servidor ?? health.criarProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServidorStatusProvider>(
            create: (_) => provider,
          ),
          ChangeNotifierProvider(create: (_) => AuthProvider(repository: auth)),
        ],
        child: MaterialApp(
          theme: tema ?? AppTheme.light,
          initialRoute: rota,
          routes: {
            '/login': (_) => const LoginPage(),
            '/cadastro': (_) => const CadastroPage(),
            '/entrando': (_) => const Scaffold(body: Text('ENTRANDO')),
            '/onboarding': (_) => const Scaffold(body: Text('ONBOARDING')),
          },
        ),
      ),
    );
    return provider;
  }

  /// Desmonta (o provider é descartado junto) e deixa vencer os timeouts das
  /// tentativas penduradas, para o teste terminar sem timer pendente.
  Future<void> encerrar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }

  /// Responde o `/health`. A resposta só é processada depois do primeiro
  /// frame, então o aviso muda no segundo.
  Future<void> responder(WidgetTester tester) async {
    health.responder();
    await tester.pump();
    await tester.pump();
  }

  Finder aviso() => find.byKey(const ValueKey('aviso-servidor'));

  Future<void> preencherLogin(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'ana@teste.com',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Senha'), '123456');
  }

  Future<void> preencherCadastro(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), 'Ana');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ana@teste.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      '123456',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar Senha'),
      '123456',
    );
  }

  Future<void> tocarNoBotao(WidgetTester tester, String texto) async {
    final botao = find.widgetWithText(OutlinedButton, texto);
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pump();
  }

  Finder aguardando() => find.text('Aguardando servidor…');

  group('aviso', () {
    testWidgets('/health rápido: nenhum aviso aparece', (tester) async {
      await montar(tester);
      await tester.pump(const Duration(seconds: 2));
      await responder(tester);
      await tester.pump(const Duration(seconds: 5));

      expect(aviso(), findsNothing);
      expect(find.textContaining('servidor'), findsNothing);
      await encerrar(tester);
    });

    testWidgets(
      '/health lento: aviso aos 3s, contador avança, "Servidor pronto" e some',
      (tester) async {
        await montar(tester);
        await tester.pump(const Duration(seconds: 2));
        expect(aviso(), findsNothing);

        await tester.pump(const Duration(seconds: 1));
        expect(aviso(), findsOneWidget);
        expect(find.text('Conectando ao servidor…'), findsOneWidget);
        expect(find.text('3s'), findsOneWidget);
        expect(
          find.text('Na primeira vez do dia pode levar até 1 minuto.'),
          findsOneWidget,
        );

        await tester.pump(const Duration(seconds: 1));
        expect(find.text('4s'), findsOneWidget);
        await tester.pump(const Duration(seconds: 8));
        expect(find.text('12s'), findsOneWidget);
        // Tempo decorrido, nunca contagem regressiva.
        expect(find.textContaining('faltam'), findsNothing);

        await responder(tester);
        expect(find.text('Servidor pronto'), findsOneWidget);
        expect(find.text('Conectando ao servidor…'), findsNothing);

        await tester.pump(const Duration(seconds: 2));
        expect(aviso(), findsNothing);
        await encerrar(tester);
      },
    );

    testWidgets(
      '/health que nunca responde: erro aos 90s e "Tentar de novo" reinicia',
      (tester) async {
        await montar(tester);
        await tester.pump(const Duration(seconds: 89));
        expect(find.text('Conectando ao servidor…'), findsOneWidget);
        expect(find.text('89s'), findsOneWidget);

        await tester.pump(const Duration(seconds: 1));
        expect(
          find.text('Não foi possível conectar ao servidor.'),
          findsOneWidget,
        );
        final tentar = find.widgetWithText(TextButton, 'Tentar de novo');
        expect(tentar, findsOneWidget);
        final alvo = tester.getSize(tentar);
        expect(alvo.height, greaterThanOrEqualTo(48));
        expect(alvo.width, greaterThanOrEqualTo(48));

        final chamadasAntes = health.chamadas;
        await tester.ensureVisible(tentar);
        await tester.tap(tentar);
        await tester.pump();
        expect(health.chamadas, chamadasAntes + 1);
        expect(find.text('Conectando ao servidor…'), findsOneWidget);
        expect(find.text('0s'), findsOneWidget);

        await tester.pump(const Duration(seconds: 2));
        expect(find.text('2s'), findsOneWidget);
        await responder(tester);
        expect(find.text('Servidor pronto'), findsOneWidget);
        await encerrar(tester);
      },
    );

    testWidgets('login → cadastro → login não dispara outro /health', (
      tester,
    ) async {
      await montar(tester);
      await tester.pump(const Duration(seconds: 4));
      expect(health.chamadas, 1);
      expect(aviso(), findsOneWidget);

      await tester.ensureVisible(find.text('Cadastre-se'));
      await tester.tap(find.text('Cadastre-se'));
      await tester.pumpAndSettle();
      expect(find.byType(CadastroPage), findsOneWidget);
      // O cadastro lê o mesmo estado: o aviso segue com o mesmo contador.
      expect(find.text('Conectando ao servidor…'), findsOneWidget);

      final linkEntrar = find.widgetWithText(TextButton, 'Entrar');
      await tester.ensureVisible(linkEntrar);
      await tester.tap(linkEntrar);
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      expect(health.chamadas, 1);
      await encerrar(tester);
    });

    testWidgets('mock: nenhuma chamada, nenhum aviso e login direto', (
      tester,
    ) async {
      await montar(tester, servidor: ServidorStatusProvider.pronto());
      await tester.pump(const Duration(seconds: 10));
      expect(aviso(), findsNothing);
      expect(health.chamadas, 0);

      await preencherLogin(tester);
      await tocarNoBotao(tester, 'ENTRAR');
      expect(aguardando(), findsNothing);
      await tester.pumpAndSettle();
      expect(auth.logins, 1);
      expect(find.text('ENTRANDO'), findsOneWidget);
      expect(health.chamadas, 0);
    });

    testWidgets('a região viva só tem o texto do estado, sem o contador', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await montar(tester);
      await tester.pump(const Duration(seconds: 5));

      SemanticsData dados(String rotulo) =>
          tester.getSemantics(find.bySemanticsLabel(rotulo)).getSemanticsData();

      final conectando = dados('Conectando ao servidor…');
      expect(conectando.flagsCollection.isLiveRegion, isTrue);
      expect(conectando.label, 'Conectando ao servidor…');

      final contador = dados('5 segundos');
      expect(contador.flagsCollection.isLiveRegion, isFalse);

      final dica = dados('Na primeira vez do dia pode levar até 1 minuto.');
      expect(dica.flagsCollection.isLiveRegion, isFalse);

      await responder(tester);
      final pronto = dados('Servidor pronto');
      expect(pronto.flagsCollection.isLiveRegion, isTrue);
      expect(pronto.label, 'Servidor pronto');
      semantics.dispose();
      await encerrar(tester);
    });

    testWidgets('falha também anuncia só o texto do estado', (tester) async {
      final semantics = tester.ensureSemantics();
      await montar(tester);
      await tester.pump(const Duration(seconds: 90));

      final falha = tester
          .getSemantics(
            find.bySemanticsLabel('Não foi possível conectar ao servidor.'),
          )
          .getSemanticsData();
      expect(falha.flagsCollection.isLiveRegion, isTrue);
      expect(falha.label, 'Não foi possível conectar ao servidor.');
      semantics.dispose();
      await encerrar(tester);
    });

    for (final (nome, tema, cores) in [
      ('claro', () => AppTheme.light, AppColors.light),
      ('escuro', () => AppTheme.dark, AppColors.dark),
    ]) {
      testWidgets('tema $nome: superfície, borda e texto do tema', (
        tester,
      ) async {
        await montar(tester, tema: tema());
        await tester.pump(const Duration(seconds: 4));

        final caixa = tester.widget<Container>(aviso());
        final decoracao = caixa.decoration! as BoxDecoration;
        expect(decoracao.color, cores.surface);
        expect((decoracao.border! as Border).top.color, cores.border);

        final texto = tester.widget<Text>(find.text('Conectando ao servidor…'));
        expect(texto.style?.color, cores.textPrimary);
        final dica = tester.widget<Text>(
          find.text('Na primeira vez do dia pode levar até 1 minuto.'),
        );
        expect(dica.style?.color, cores.textSecondary);
        expect(
          tester.widget<Icon>(find.byIcon(Icons.cloud_outlined)).color,
          cores.primaryAccent,
        );

        await tester.pump(const Duration(seconds: 86));
        expect(
          tester.widget<Icon>(find.byIcon(Icons.cloud_off_outlined)).color,
          cores.danger,
        );
        expect(tester.takeException(), isNull);
        await encerrar(tester);
      });
    }
  });

  group('Entrar espera o servidor', () {
    testWidgets('durante demorando: login só depois do /health, uma vez só', (
      tester,
    ) async {
      await montar(tester);
      await preencherLogin(tester);
      await tester.pump(const Duration(seconds: 4));

      await tocarNoBotao(tester, 'ENTRAR');
      expect(aguardando(), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'ENTRAR'), findsNothing);
      expect(auth.logins, 0);

      // Toque repetido e Enter no campo de senha durante a espera.
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Aguardando servidor…'),
        warnIfMissed: false,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(seconds: 6));
      expect(auth.logins, 0);

      health.responder();
      await tester.pumpAndSettle();
      expect(auth.logins, 1);
      expect(find.text('ENTRANDO'), findsOneWidget);
      await encerrar(tester);
    });

    testWidgets('ainda verificando (antes do aviso) também espera', (
      tester,
    ) async {
      await montar(tester);
      await preencherLogin(tester);
      await tocarNoBotao(tester, 'ENTRAR');
      expect(aguardando(), findsOneWidget);
      expect(auth.logins, 0);

      await tester.pump(const Duration(seconds: 1));
      health.responder();
      await tester.pumpAndSettle();
      expect(auth.logins, 1);
      await encerrar(tester);
    });

    testWidgets('/health falha: o login nunca é chamado', (tester) async {
      await montar(tester);
      await preencherLogin(tester);
      await tester.pump(const Duration(seconds: 4));
      await tocarNoBotao(tester, 'ENTRAR');

      await tester.pump(const Duration(seconds: 86));
      expect(auth.logins, 0);
      expect(
        find.text('Não foi possível conectar ao servidor.'),
        findsOneWidget,
      );
      expect(aguardando(), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'ENTRAR'), findsOneWidget);

      await tester.pump(const Duration(seconds: 30));
      expect(auth.logins, 0);
      await encerrar(tester);
    });
  });

  group('Cadastrar espera o servidor', () {
    testWidgets(
      'durante demorando: cadastro só depois do /health, uma vez só',
      (tester) async {
        await montar(tester, rota: '/cadastro');
        await preencherCadastro(tester);
        await tester.pump(const Duration(seconds: 4));

        await tocarNoBotao(tester, 'CADASTRAR');
        expect(aguardando(), findsOneWidget);
        expect(auth.cadastros, 0);

        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Aguardando servidor…'),
          warnIfMissed: false,
        );
        await tester.pump(const Duration(seconds: 6));
        expect(auth.cadastros, 0);

        health.responder();
        await tester.pumpAndSettle();
        expect(auth.cadastros, 1);
        expect(find.text('ONBOARDING'), findsOneWidget);
        await encerrar(tester);
      },
    );

    testWidgets('/health falha: o cadastro nunca é chamado', (tester) async {
      await montar(tester, rota: '/cadastro');
      await preencherCadastro(tester);
      await tester.pump(const Duration(seconds: 4));
      await tocarNoBotao(tester, 'CADASTRAR');

      await tester.pump(const Duration(seconds: 86));
      expect(auth.cadastros, 0);
      expect(
        find.text('Não foi possível conectar ao servidor.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'CADASTRAR'), findsOneWidget);

      await tester.pump(const Duration(seconds: 30));
      expect(auth.cadastros, 0);
      await encerrar(tester);
    });

    testWidgets('formulário inválido não fica esperando o servidor', (
      tester,
    ) async {
      await montar(tester, rota: '/cadastro');
      await tester.pump(const Duration(seconds: 4));
      await tocarNoBotao(tester, 'CADASTRAR');

      expect(aguardando(), findsNothing);
      expect(find.text('Informe um email válido.'), findsOneWidget);
      await encerrar(tester);
    });
  });

  testWidgets('o aviso fica logo acima do botão principal', (tester) async {
    await montar(tester);
    await tester.pump(const Duration(seconds: 4));

    final baseDoAviso = tester.getBottomLeft(aviso()).dy;
    final topoDoBotao = tester
        .getTopLeft(find.widgetWithText(OutlinedButton, 'ENTRAR'))
        .dy;
    expect(topoDoBotao, greaterThan(baseDoAviso));
    expect(
      tester.getTopLeft(find.text('Esqueci minha senha')).dy,
      lessThan(tester.getTopLeft(aviso()).dy),
    );
    expect(find.byType(AvisoServidorBanner), findsOneWidget);
    await encerrar(tester);
  });
}
