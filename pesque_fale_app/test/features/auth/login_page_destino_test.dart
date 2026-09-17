import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/presentation/login/login_page.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';

/// Devolve um usuário com [onboardingConcluido] controlado pelo teste, para
/// exercitar a decisão de destino pós-login.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.onboardingConcluido});

  final bool onboardingConcluido;

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
    return AuthResult(
      accessToken: 'token',
      usuario: Usuario(
        id: 'user-1',
        nome: 'Ana',
        email: email,
        onboardingConcluido: onboardingConcluido,
      ),
    );
  }

  @override
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montarELogar(
    WidgetTester tester, {
    required bool onboardingConcluido,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              repository: _FakeAuthRepository(
                onboardingConcluido: onboardingConcluido,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          routes: {
            '/login': (_) => const LoginPage(),
            '/home': (_) => const Scaffold(body: Text('FEED')),
            '/onboarding': (_) => const Scaffold(body: Text('TUTORIAL')),
          },
          initialRoute: '/login',
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'ana@teste.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Senha'),
      '123456',
    );

    // AuthPrimaryButton renderiza o label em caixa alta e fica abaixo da
    // dobra no viewport padrao do teste.
    final botaoEntrar = find.widgetWithText(OutlinedButton, 'ENTRAR');
    await tester.ensureVisible(botaoEntrar);
    await tester.pumpAndSettle();

    await tester.tap(botaoEntrar);
    await tester.pumpAndSettle();
  }

  group('LoginPage — destino pos-login', () {
    testWidgets('usuario com onboardingConcluido true vai para /home', (
      tester,
    ) async {
      await montarELogar(tester, onboardingConcluido: true);

      expect(find.text('FEED'), findsOneWidget);
      expect(find.text('TUTORIAL'), findsNothing);
    });

    testWidgets('usuario com onboardingConcluido false vai para /onboarding', (
      tester,
    ) async {
      await montarELogar(tester, onboardingConcluido: false);

      expect(find.text('TUTORIAL'), findsOneWidget);
      expect(find.text('FEED'), findsNothing);
    });
  });
}
