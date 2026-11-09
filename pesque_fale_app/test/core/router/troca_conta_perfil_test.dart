import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pesque_fale_app/core/data/paged_result.dart';
import 'package:pesque_fale_app/core/realtime/realtime_manager.dart';
import 'package:pesque_fale_app/core/router/main_shell.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/core/theme/theme_provider.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/chat/data/conversas_repository.dart';
import 'package:pesque_fale_app/features/chat/domain/conversa.dart';
import 'package:pesque_fale_app/features/chat/providers/badge_mensagens_provider.dart';
import 'package:pesque_fale_app/features/chat/providers/inbox_provider.dart';
import 'package:pesque_fale_app/features/clima/data/clima_repository.dart';
import 'package:pesque_fale_app/features/clima/data/localizacao_service.dart';
import 'package:pesque_fale_app/features/clima/domain/clima.dart';
import 'package:pesque_fale_app/features/clima/domain/condicao_clima.dart';
import 'package:pesque_fale_app/features/clima/providers/clima_provider.dart';
import 'package:pesque_fale_app/features/configuracoes/presentation/configuracoes_page.dart';
import 'package:pesque_fale_app/features/configuracoes/providers/preferencias_provider.dart';
import 'package:pesque_fale_app/features/feed/data/comentarios_repository.dart';
import 'package:pesque_fale_app/features/feed/data/curtidas_repository.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/comentario.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/notificacoes/data/notificacoes_repository.dart';
import 'package:pesque_fale_app/features/notificacoes/domain/notificacao.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/badge_notificacoes_provider.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository.dart';
import 'package:pesque_fale_app/features/perfil/domain/perfil_completo.dart';
import 'package:pesque_fale_app/features/perfil/presentation/perfil_page.dart';
import 'package:pesque_fale_app/features/perfil/providers/perfil_provider.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_repository.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/filtros_locais.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/ponto.dart';
import 'package:pesque_fale_app/features/pesquisa/providers/pesquisa_locais_provider.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/data/avaliacoes_repository.dart';
import 'package:pesque_fale_app/features/tour/domain/tour_status_storage.dart';
import 'package:pesque_fale_app/features/tour/providers/tour_provider.dart';

import '../../features/chat/support/fake_realtime_manager.dart';

// Regressão: na v1.1.0, depois de sair da conta A e criar (ou entrar com) a
// conta B, a aba Perfil mostrava o perfil de A com o botão "Seguir". Aqui o
// app roda pelo mesmo caminho do `main.dart`: MainShell com a GlobalKey,
// saída pela tela de Configurações de verdade e volta para '/home' pelo
// `pushNamedAndRemoveUntil` do fim do onboarding (cadastro) ou pelo login.
//
// Repositórios falsos, sem rede e sem imagem.

const _contaA = Usuario(
  id: 'conta-a',
  nome: 'Ana Antiga',
  email: 'ana@teste.com',
  username: 'ana_antiga',
  bio: 'Bio da conta A',
  onboardingConcluido: true,
);

const _contaB = Usuario(
  id: 'conta-b',
  nome: 'Bruno Novo',
  email: 'bruno@teste.com',
  username: 'bruno_novo',
  bio: 'Bio da conta B',
  onboardingConcluido: true,
);

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async => AuthResult(
    accessToken: 'token-$email',
    usuario: email == _contaA.email ? _contaA : _contaB,
  );

  @override
  Future<void> logout() async {}

  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async => const AuthResult(accessToken: 'token-b', usuario: _contaB);
}

class _FakePerfilRepository implements PerfilRepository {
  final pedidos = <String>[];

  /// Ids cujo próximo `buscarPerfil` fica pendurado até o teste completar o
  /// [Completer] guardado em [pendentes] (simula a API lenta, ex.: cold start).
  final segurarProximo = <String>{};
  final pendentes = <String, Completer<PerfilCompleto>>{};

  PerfilCompleto _perfilDe(String id) =>
      PerfilCompleto(usuario: id == _contaA.id ? _contaA : _contaB);

  void completarPendente(String id) =>
      pendentes.remove(id)!.complete(_perfilDe(id));

  @override
  Future<PerfilCompleto> buscarPerfil(String id, {required String meuId}) {
    pedidos.add(id);
    if (segurarProximo.remove(id)) {
      final pendente = Completer<PerfilCompleto>();
      pendentes[id] = pendente;
      return pendente.future;
    }
    return Future.value(_perfilDe(id));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePublicacoesRepository implements PublicacoesRepository {
  @override
  Future<PagedResult<Publicacao>> listar({
    int pagina = 1,
    int porPagina = 20,
    bool seguindo = false,
  }) async => PagedResult(
    items: const [],
    total: 0,
    pagina: pagina,
    porPagina: porPagina,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCurtidasRepository implements CurtidasRepository {
  @override
  Future<void> curtir(String publicacaoId) async {}

  @override
  Future<void> descurtir(String publicacaoId) async {}
}

class _FakeComentariosRepository implements ComentariosRepository {
  @override
  Future<PagedResult<Comentario>> listar(
    String publicacaoId, {
    int pagina = 1,
    int porPagina = 20,
  }) async => const PagedResult(items: [], total: 0, pagina: 1, porPagina: 20);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEventosRepository implements EventosRepository {
  @override
  Future<List<Evento>> listar({bool futuros = true, int limite = 10}) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePontosRepository implements PontosRepository {
  @override
  Future<List<Ponto>> buscar({
    required FiltrosLocais filtros,
    double? lat,
    double? lng,
    bool incluirDistancia = false,
    String? ordem,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConversasRepository implements ConversasRepository {
  @override
  Future<List<Conversa>> listar() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotificacoesRepository implements NotificacoesRepository {
  @override
  Future<({List<Notificacao> lista, int naoLidas})> listar({
    int pagina = 1,
    int porPagina = 20,
  }) async => (lista: const <Notificacao>[], naoLidas: 0);

  @override
  Future<int> contarNaoLidas() async => 0;

  @override
  Future<void> marcarTodasComoLidas() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAvaliacoesRepository implements AvaliacoesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClimaRepository implements ClimaRepository {
  @override
  Future<Clima> buscarAtual({
    required double latitude,
    required double longitude,
  }) async => const Clima(
    temperatura: 21.6,
    umidade: 83,
    ventoKmh: 7.2,
    condicao: CondicaoClima.chuva,
  );
}

class _FakeLocalizacao implements LocalizacaoService {
  @override
  Future<ResultadoLocalizacao> obter({required bool pedirPermissao}) async =>
      const LocalizacaoObtida(latitude: -21.6, longitude: -48.36);

  @override
  Future<void> abrirConfiguracoes(MotivoSemLocalizacao motivo) async {}
}

/// Canal do flutter_secure_storage em memória, com o tour já visto para as
/// duas contas (o tour não é o assunto aqui).
void _fakeSecureStorage() {
  final dados = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async {
          final args = (call.arguments as Map).cast<String, dynamic>();
          final chave = args['key'] as String?;
          switch (call.method) {
            case 'read':
              return dados[chave] ?? (chave != null ? 'true' : null);
            case 'write':
              dados[chave!] = args['value'] as String;
              return null;
            case 'delete':
              dados.remove(chave);
              return null;
            case 'containsKey':
              return true;
            case 'readAll':
              return dados;
            case 'deleteAll':
              dados.clear();
              return null;
          }
          return null;
        },
      );
}

/// Tela de entrada simplificada: no app real, cadastro e login passam pelo
/// onboarding/'/entrando' e terminam empurrando '/home'. O que importa aqui é
/// o mesmo `AuthProvider` e a mesma rota '/home' com a GlobalKey do shell.
class _TelaEntrada extends StatelessWidget {
  const _TelaEntrada();

  Future<void> _irParaHome(BuildContext context) async {
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () async {
              await auth.login(email: _contaA.email, senha: 'senha');
              if (context.mounted) await _irParaHome(context);
            },
            child: const Text('Entrar como A'),
          ),
          TextButton(
            onPressed: () async {
              await auth.cadastrar(
                nome: _contaB.nome,
                email: _contaB.email,
                senha: 'senha123',
                confirmarSenha: 'senha123',
              );
              if (context.mounted) await _irParaHome(context);
            },
            child: const Text('Criar conta B'),
          ),
          TextButton(
            onPressed: () async {
              await auth.login(email: _contaB.email, senha: 'senha');
              if (context.mounted) await _irParaHome(context);
            },
            child: const Text('Entrar como B'),
          ),
        ],
      ),
    );
  }
}

/// Mesma árvore de providers do `main.dart`, com repositórios falsos.
Widget _app(_FakePerfilRepository perfilRepo) {
  final auth = AuthProvider(repository: _FakeAuthRepository());
  final publicacoesRepo = _FakePublicacoesRepository();
  final curtidasRepo = _FakeCurtidasRepository();
  final eventosRepo = _FakeEventosRepository();
  final pontosRepo = _FakePontosRepository();
  final store = PublicacoesStore();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => PreferenciasProvider()),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProxyProvider<AuthProvider, RealtimeManager>(
        lazy: false,
        create: (_) => FakeRealtimeManager(),
        update: (_, auth, previous) => previous!..reagirAuth(auth),
      ),
      ChangeNotifierProvider<PublicacoesStore>.value(value: store),
      Provider<PerfilRepository>.value(value: perfilRepo),
      ChangeNotifierProxyProvider2<
        AuthProvider,
        RealtimeManager,
        PerfilProvider
      >(
        lazy: false,
        create: (ctx) => PerfilProvider(
          repository: perfilRepo,
          authProvider: ctx.read<AuthProvider>(),
          store: store,
          realtime: ctx.read<RealtimeManager>(),
        ),
        update: (_, auth, _, previous) => previous!..rebindAuth(auth),
      ),
      Provider<PontosRepository>.value(value: pontosRepo),
      ChangeNotifierProvider<ClimaProvider>(
        create: (_) => ClimaProvider(
          repository: _FakeClimaRepository(),
          localizacao: _FakeLocalizacao(),
        ),
      ),
      Provider<AvaliacoesRepository>.value(value: _FakeAvaliacoesRepository()),
      ChangeNotifierProvider<PesquisaLocaisProvider>(
        create: (_) => PesquisaLocaisProvider(repository: pontosRepo),
      ),
      Provider<PublicacoesRepository>.value(value: publicacoesRepo),
      Provider<CurtidasRepository>.value(value: curtidasRepo),
      Provider<ComentariosRepository>.value(
        value: _FakeComentariosRepository(),
      ),
      Provider<EventosRepository>.value(value: eventosRepo),
      Provider<ConversasRepository>.value(value: _FakeConversasRepository()),
      Provider<NotificacoesRepository>.value(
        value: _FakeNotificacoesRepository(),
      ),
      ChangeNotifierProxyProvider2<
        AuthProvider,
        RealtimeManager,
        NotificacoesProvider
      >(
        lazy: false,
        create: (ctx) => NotificacoesProvider(
          repository: ctx.read<NotificacoesRepository>(),
          perfilRepository: perfilRepo,
          realtime: ctx.read<RealtimeManager>(),
        ),
        update: (_, auth, _, previous) => previous!..reagirAuth(auth),
      ),
      ChangeNotifierProxyProvider<
        NotificacoesProvider,
        BadgeNotificacoesProvider
      >(
        create: (ctx) => BadgeNotificacoesProvider(
          notificacoes: ctx.read<NotificacoesProvider>(),
        ),
        update: (_, notificacoes, previous) =>
            previous ?? BadgeNotificacoesProvider(notificacoes: notificacoes),
      ),
      ChangeNotifierProxyProvider2<
        AuthProvider,
        RealtimeManager,
        InboxProvider
      >(
        lazy: false,
        create: (ctx) => InboxProvider(
          repository: ctx.read<ConversasRepository>(),
          realtime: ctx.read<RealtimeManager>(),
        ),
        update: (_, auth, _, previous) => previous!..reagirAuth(auth),
      ),
      ChangeNotifierProxyProvider<InboxProvider, BadgeMensagensProvider>(
        create: (ctx) =>
            BadgeMensagensProvider(inbox: ctx.read<InboxProvider>()),
        update: (_, inbox, previous) =>
            previous ?? BadgeMensagensProvider(inbox: inbox),
      ),
      ChangeNotifierProxyProvider2<AuthProvider, RealtimeManager, FeedProvider>(
        lazy: false,
        create: (ctx) => FeedProvider(
          publicacoesRepo: publicacoesRepo,
          curtidasRepo: curtidasRepo,
          eventosRepo: eventosRepo,
          pontosRepo: pontosRepo,
          authProvider: ctx.read<AuthProvider>(),
          realtime: ctx.read<RealtimeManager>(),
          store: store,
        ),
        update: (_, auth, _, previous) => previous!..reagirAuth(auth),
      ),
      Provider<TourStatusStorage>(
        create: (_) => TourStatusStorage(storage: const FlutterSecureStorage()),
      ),
      ChangeNotifierProvider<TourProvider>(
        create: (ctx) => TourProvider(
          storage: ctx.read<TourStatusStorage>(),
          authProvider: auth,
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      initialRoute: '/cadastro',
      routes: {
        '/cadastro': (_) => const _TelaEntrada(),
        '/configuracoes': (_) => const ConfiguracoesPage(),
      },
      // Igual ao main.dart: '/home' monta o shell com a GlobalKey.
      onGenerateRoute: (settings) {
        if (settings.name != '/home') return null;
        return PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, _, _) => MainShell(key: MainShell.shellKey),
          transitionsBuilder: (_, animacao, _, child) =>
              FadeTransition(opacity: animacao, child: child),
        );
      },
    ),
  );
}

void _telaDeCelular(WidgetTester tester) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1080, 2400);
  addTearDown(tester.view.reset);
}

Finder _destino(String rotulo) => find.descendant(
  of: find.byType(NavigationBar),
  matching: find.text(rotulo),
);

Finder _naAbaPerfil(Finder alvo) =>
    find.descendant(of: find.byType(PerfilPage), matching: alvo);

PerfilProvider _perfilProvider(WidgetTester tester) =>
    tester.element(find.byType(PerfilPage)).read<PerfilProvider>();

Future<void> _abrirAbaPerfil(WidgetTester tester) async {
  await tester.tap(_destino('Perfil'));
  await tester.pumpAndSettle();
}

/// Ajustes (no próprio perfil) → Configurações → Sair → confirmar. É o
/// caminho real: `ConfiguracoesPage._sair` faz o signOut e volta para
/// '/cadastro' removendo o shell da pilha.
Future<void> _sairPelasConfiguracoes(WidgetTester tester) async {
  await tester.tap(_naAbaPerfil(find.text('Ajustes')));
  await tester.pumpAndSettle();
  expect(find.byType(ConfiguracoesPage), findsOneWidget);

  final sair = find.widgetWithText(ListTile, 'Sair da conta');
  await tester.scrollUntilVisible(sair, 200);
  await tester.tap(sair);
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: find.byType(AlertDialog), matching: find.text('Sair')),
  );
  await tester.pumpAndSettle();

  expect(find.byType(MainShell), findsNothing);
  expect(find.text('Entrar como A'), findsOneWidget);
}

/// Avança 1 s de relógio em passos de 100 ms (para telas com animação em
/// loop, como o skeleton do perfil, em que o `pumpAndSettle` não termina).
Future<void> _avancar(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Mesmos passos do `ConfiguracoesPage._sair`, sem passar pela tela.
Future<void> _sairComoAsConfiguracoes(WidgetTester tester) async {
  final context = tester.element(find.byType(MainShell));
  final badge = context.read<BadgeNotificacoesProvider>();
  final badgeChat = context.read<BadgeMensagensProvider>();
  final navigator = Navigator.of(context);
  await context.read<AuthProvider>().signOut();
  badge.resetar();
  badgeChat.resetar();
  navigator.pushNamedAndRemoveUntil('/cadastro', (_) => false);
  await _avancar(tester);
  await tester.pumpAndSettle();
  expect(find.byType(MainShell), findsNothing);
}

/// Confere que a aba Perfil mostra o [dono] como próprio perfil: dados dele,
/// "Editar perfil" e "Ajustes", e nenhum vestígio da [outra] conta.
void _confereProprioPerfil(
  WidgetTester tester, {
  required Usuario dono,
  required Usuario outra,
}) {
  final provider = _perfilProvider(tester);
  expect(provider.perfil?.id, dono.id, reason: 'perfil carregado');
  expect(provider.isOwnProfile, isTrue, reason: 'isOwnProfile');

  expect(_naAbaPerfil(find.text(dono.nome)), findsWidgets);
  expect(_naAbaPerfil(find.text(dono.bio!)), findsOneWidget);
  expect(_naAbaPerfil(find.text(outra.nome)), findsNothing);
  expect(_naAbaPerfil(find.text(outra.bio!)), findsNothing);

  expect(_naAbaPerfil(find.text('Editar perfil')), findsOneWidget);
  expect(_naAbaPerfil(find.text('Ajustes')), findsOneWidget);
  expect(_naAbaPerfil(find.text('Seguir')), findsNothing);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _fakeSecureStorage();
  });

  for (final (rotulo, botaoB) in [
    ('cria a conta B', 'Criar conta B'),
    ('entra com a conta B já existente', 'Entrar como B'),
  ]) {
    testWidgets('aba Perfil mostra a conta nova depois que A sai e $rotulo', (
      tester,
    ) async {
      _telaDeCelular(tester);
      final perfilRepo = _FakePerfilRepository();
      await tester.pumpWidget(_app(perfilRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrar como A'));
      await tester.pumpAndSettle();
      await _abrirAbaPerfil(tester);
      _confereProprioPerfil(tester, dono: _contaA, outra: _contaB);

      await _sairPelasConfiguracoes(tester);

      await tester.tap(find.text(botaoB));
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);

      await _abrirAbaPerfil(tester);
      _confereProprioPerfil(tester, dono: _contaB, outra: _contaA);
      expect(perfilRepo.pedidos.last, _contaB.id);
    });
  }

  // Hipótese da resposta atrasada (regra D9): a API demora a responder o
  // perfil de A (ex.: cold start do Render), a pessoa sai e entra com B, e a
  // resposta de A chega depois da de B. Ela não pode sobrescrever B.
  testWidgets(
    'resposta atrasada do perfil de A não sobrescreve o perfil de B',
    (tester) async {
      _telaDeCelular(tester);
      final perfilRepo = _FakePerfilRepository()
        ..segurarProximo.add(_contaA.id);
      await tester.pumpWidget(_app(perfilRepo));
      await tester.pumpAndSettle();

      // O skeleton do perfil de A fica animando enquanto a requisição está
      // pendente: avança o relógio em vez de esperar assentar.
      await tester.tap(find.text('Entrar como A'));
      await _avancar(tester);
      await tester.tap(_destino('Perfil'));
      await _avancar(tester);
      expect(perfilRepo.pendentes.keys, [_contaA.id]);
      expect(_perfilProvider(tester).status, PerfilStatus.loading);

      // Com o perfil ainda carregando não há botão "Ajustes" na tela: faz o
      // mesmo que o `ConfiguracoesPage._sair`.
      await _sairComoAsConfiguracoes(tester);

      await tester.tap(find.text('Entrar como B'));
      await tester.pumpAndSettle();
      await _abrirAbaPerfil(tester);
      _confereProprioPerfil(tester, dono: _contaB, outra: _contaA);

      perfilRepo.completarPendente(_contaA.id);
      await tester.pumpAndSettle();

      _confereProprioPerfil(tester, dono: _contaB, outra: _contaA);
    },
  );

  // Hipótese do state sobrevivente: se a conta trocar com o shell ainda na
  // tela, a PerfilPage (viva no IndexedStack) precisa buscar o perfil novo,
  // e não só o que pediu no initState.
  testWidgets('troca de conta com o shell montado recarrega a aba Perfil', (
    tester,
  ) async {
    _telaDeCelular(tester);
    final perfilRepo = _FakePerfilRepository();
    await tester.pumpWidget(_app(perfilRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como A'));
    await tester.pumpAndSettle();
    await _abrirAbaPerfil(tester);
    _confereProprioPerfil(tester, dono: _contaA, outra: _contaB);

    final auth = tester.element(find.byType(MainShell)).read<AuthProvider>();
    await auth.signOut();
    await auth.login(email: _contaB.email, senha: 'senha');
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    _confereProprioPerfil(tester, dono: _contaB, outra: _contaA);
    expect(perfilRepo.pedidos, [_contaA.id, _contaB.id]);
  });
}
