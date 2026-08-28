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
import 'package:pesque_fale_app/features/onboarding/domain/onboarding_status_storage.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/etapas/onboarding_boas_vindas_page.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/widgets/onboarding_botao_principal.dart';
import 'package:pesque_fale_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository.dart';
import 'package:pesque_fale_app/features/perfil/domain/perfil_completo.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.nome = 'Ana'});
  final String nome;

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
        id: '1',
        nome: nome,
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

  Future<OnboardingProvider> montarWidget(
    WidgetTester tester, {
    String nome = 'Ana',
  }) async {
    final authProvider = AuthProvider(
      repository: _FakeAuthRepository(nome: nome),
    );
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
          home: const OnboardingBoasVindasPage(),
        ),
      ),
    );
    await tester.pump();
    return onboardingProvider;
  }

  testWidgets('renderiza titulo com o nome do usuario quando presente', (
    tester,
  ) async {
    await montarWidget(tester, nome: 'Ana Pescadora');

    expect(
      find.textContaining('Bem-vindo ao Pesque & Fale, Ana Pescadora!'),
      findsOneWidget,
    );
  });

  testWidgets('renderiza titulo generico quando nome vazio', (tester) async {
    await montarWidget(tester, nome: '');

    expect(find.text('Bem-vindo ao Pesque & Fale!'), findsOneWidget);
  });

  testWidgets('renderiza os 5 itens do card', (tester) async {
    await montarWidget(tester);

    expect(find.text('Foto de perfil'), findsOneWidget);
    expect(find.text('Nome e localização'), findsOneWidget);
    expect(find.text('Username único'), findsOneWidget);
    expect(find.text('Bio'), findsOneWidget);
    expect(find.text('Foto de capa'), findsOneWidget);
  });

  testWidgets('nao renderiza link de pular esta etapa', (tester) async {
    await montarWidget(tester);

    expect(find.text('Pular esta etapa'), findsNothing);
  });

  testWidgets('tap no botao principal chama provider.avancar', (
    tester,
  ) async {
    final provider = await montarWidget(tester);

    await tester.tap(find.byType(OnboardingBotaoPrincipal));
    await tester.pump();

    expect(provider.etapaAtual.index, 1);
  });
}
