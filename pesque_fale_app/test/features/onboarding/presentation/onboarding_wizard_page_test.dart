import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/core/theme/theme_provider.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/onboarding/domain/onboarding_etapa.dart';
import 'package:pesque_fale_app/features/onboarding/domain/onboarding_status_storage.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/etapas/onboarding_boas_vindas_page.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/etapas/onboarding_sucesso_page.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/onboarding_wizard_page.dart';
import 'package:pesque_fale_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository.dart';
import 'package:pesque_fale_app/features/perfil/domain/perfil_completo.dart';

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
        id: '1',
        nome: 'Ana',
        email: 'ana@teste.com',
        onboardingConcluido: false,
      ),
    );
  }

  @override
  Future<void> logout() async {}
}

class _FakePerfilRepository implements PerfilRepository {
  @override
  Future<PerfilCompleto> buscarPerfil(
    String id, {
    required String meuId,
  }) async => throw UnimplementedError();

  @override
  Future<void> seguir(String id) async {}

  @override
  Future<void> deixarDeSeguir(String id) async {}

  @override
  Future<String> atualizarFoto(File arquivo) async => '';

  @override
  Future<String> atualizarBanner(File arquivo) async => '';

  @override
  Future<Usuario> editarPerfil(Map<String, dynamic> camposAlterados) async =>
      throw UnimplementedError();

  @override
  Future<bool> verificarUsername(String username) async => true;
}

class _FakeStatusStorage extends OnboardingStatusStorage {
  @override
  Future<bool> isConcluido(String userId) async => false;

  @override
  Future<void> marcarConcluido(String userId) async {}

  @override
  Future<void> limpar(String userId) async {}
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<OnboardingProvider> montarWizard(WidgetTester tester) async {
    final authProvider = AuthProvider(repository: _FakeAuthRepository());
    await authProvider.login(email: 'ana@teste.com', senha: '123456');

    late OnboardingProvider onboardingProvider;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<OnboardingProvider>(
            create: (_) {
              onboardingProvider = OnboardingProvider(
                perfilRepository: _FakePerfilRepository(),
                authProvider: authProvider,
                statusStorage: _FakeStatusStorage(),
              );
              return onboardingProvider;
            },
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OnboardingWizardPage(),
                    ),
                  ),
                  child: const Text('abrir wizard'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir wizard'));
    await tester.pumpAndSettle();
    return onboardingProvider;
  }

  testWidgets('etapa boasVindas renderiza OnboardingBoasVindasPage', (
    tester,
  ) async {
    await montarWizard(tester);

    expect(find.byType(OnboardingBoasVindasPage), findsOneWidget);
  });

  testWidgets('etapa sucesso renderiza OnboardingSucessoPage', (
    tester,
  ) async {
    final provider = await montarWizard(tester);

    while (provider.etapaAtual != OnboardingEtapa.sucesso) {
      provider.avancar();
    }
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingSucessoPage), findsOneWidget);
  });

  testWidgets('back button na etapa 1 permite o pop da rota', (
    tester,
  ) async {
    await montarWizard(tester);

    final context = tester.element(find.byType(OnboardingWizardPage));
    final popped = await Navigator.of(context).maybePop();
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(find.byType(OnboardingWizardPage), findsNothing);
    expect(find.text('abrir wizard'), findsOneWidget);
  });

  testWidgets('back button em etapa intermediaria chama provider.voltar', (
    tester,
  ) async {
    final provider = await montarWizard(tester);

    provider.avancar();
    provider.avancar();
    await tester.pumpAndSettle();
    expect(provider.etapaAtual, OnboardingEtapa.nomeLocalizacao);

    final context = tester.element(find.byType(OnboardingWizardPage));
    // maybePop() retorna true tanto quando a rota e removida quanto quando o
    // pop e bloqueado (RoutePopDisposition.doNotPop) — o que importa aqui e
    // que a rota continua na pilha e o provider voltou uma etapa.
    await Navigator.of(context).maybePop();
    await tester.pumpAndSettle();

    expect(provider.etapaAtual, OnboardingEtapa.fotoPerfil);
    expect(find.byType(OnboardingWizardPage), findsOneWidget);
  });
}
