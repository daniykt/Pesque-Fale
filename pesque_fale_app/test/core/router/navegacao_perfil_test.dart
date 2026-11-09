import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pesque_fale_app/core/router/main_shell.dart';
import 'package:pesque_fale_app/core/router/navegacao_perfil.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';

const _meuId = 'user-1';
const _outroId = 'user-2';

/// Loga sempre o mesmo usuário, para os testes compararem o id tocado com o
/// id do usuário logado.
class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async => throw UnimplementedError();

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async {
    return const AuthResult(
      accessToken: 'token',
      usuario: Usuario(
        id: _meuId,
        nome: 'Ana',
        email: 'ana@teste.com',
        onboardingConcluido: true,
      ),
    );
  }

  @override
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  /// Monta um app com '/home' na raiz, expondo um botão que chama
  /// [abrirPerfil] com o id informado. Registra as rotas visitadas e as abas
  /// selecionadas para as asserções.
  Future<
    ({
      List<int> abasSelecionadas,
      List<String> rotasEmpurradas,
      List<Object?> argumentos,
    })
  >
  montarWidget(
    WidgetTester tester, {
    required String usuarioIdTocado,
    bool comUsuarioLogado = true,
  }) async {
    final abasSelecionadas = <int>[];
    final rotasEmpurradas = <String>[];
    final argumentos = <Object?>[];

    final authProvider = AuthProvider(repository: _FakeAuthRepository());
    if (comUsuarioLogado) {
      await authProvider.login(email: 'ana@teste.com', senha: '123456');
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp(
          theme: AppTheme.light,
          initialRoute: '/home',
          onGenerateRoute: (settings) {
            if (settings.name != null && settings.name != '/home') {
              rotasEmpurradas.add(settings.name!);
            }
            if (settings.name == '/perfil') {
              argumentos.add(settings.arguments);
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const Scaffold(body: Text('tela perfil')),
              );
            }
            if (settings.name == '/empilhada') {
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('tela empilhada'),
                        ElevatedButton(
                          onPressed: () => abrirPerfil(
                            context,
                            usuarioIdTocado,
                            onSelecionarAba: abasSelecionadas.add,
                          ),
                          child: const Text('ver perfil empilhada'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => abrirPerfil(
                      context,
                      usuarioIdTocado,
                      onSelecionarAba: abasSelecionadas.add,
                    ),
                    child: const Text('ver perfil'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    // initialRoute '/home' faz o Navigator gerar a cadeia '/' -> '/home'.
    // Só interessam as rotas empurradas depois da montagem.
    rotasEmpurradas.clear();

    return (
      abasSelecionadas: abasSelecionadas,
      rotasEmpurradas: rotasEmpurradas,
      argumentos: argumentos,
    );
  }

  testWidgets('id de outro usuario empurra /perfil com o id em arguments', (
    tester,
  ) async {
    final r = await montarWidget(tester, usuarioIdTocado: _outroId);

    await tester.tap(find.text('ver perfil'));
    await tester.pumpAndSettle();

    expect(r.rotasEmpurradas, ['/perfil']);
    expect(r.argumentos, [_outroId]);
    expect(find.text('tela perfil'), findsOneWidget);
    expect(r.abasSelecionadas, isEmpty);
  });

  testWidgets('id do proprio usuario seleciona a aba Perfil sem empurrar rota', (
    tester,
  ) async {
    final r = await montarWidget(tester, usuarioIdTocado: _meuId);

    await tester.tap(find.text('ver perfil'));
    await tester.pumpAndSettle();

    expect(r.rotasEmpurradas, isEmpty);
    expect(find.text('tela perfil'), findsNothing);
    expect(r.abasSelecionadas, [MainShell.perfilIndex]);
  });

  testWidgets('proprio usuario com tela empilhada volta ate /home', (
    tester,
  ) async {
    final r = await montarWidget(tester, usuarioIdTocado: _meuId);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/empilhada');
    await tester.pumpAndSettle();
    expect(find.text('tela empilhada'), findsOneWidget);

    // Chamada feita de dentro da tela empilhada: o popUntil tem trabalho real.
    await tester.tap(find.text('ver perfil empilhada'));
    await tester.pumpAndSettle();

    expect(find.text('tela empilhada'), findsNothing);
    expect(find.text('ver perfil'), findsOneWidget);
    expect(r.abasSelecionadas, [MainShell.perfilIndex]);
  });

  testWidgets('sem usuario logado empurra /perfil normalmente', (tester) async {
    final r = await montarWidget(
      tester,
      usuarioIdTocado: _meuId,
      comUsuarioLogado: false,
    );

    await tester.tap(find.text('ver perfil'));
    await tester.pumpAndSettle();

    expect(r.rotasEmpurradas, ['/perfil']);
    expect(r.argumentos, [_meuId]);
    expect(find.text('tela perfil'), findsOneWidget);
    expect(r.abasSelecionadas, isEmpty);
  });
}
