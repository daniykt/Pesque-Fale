import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/core/theme/theme_provider.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/onboarding/domain/onboarding_status_storage.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/etapas/onboarding_bio_page.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/widgets/onboarding_link_pular.dart';
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

  Future<OnboardingProvider> montarWidget(WidgetTester tester) async {
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
          home: const OnboardingBioPage(),
        ),
      ),
    );
    await tester.pump();
    return onboardingProvider;
  }

  testWidgets('renderiza campo com placeholder e limite de 300 caracteres', (
    tester,
  ) async {
    await montarWidget(tester);

    expect(
      find.text('Sou pescador há 10 anos, adoro pescar em rios de água doce...'),
      findsOneWidget,
    );
    final campo = tester.widget<TextField>(find.byType(TextField));
    expect(campo.maxLength, 300);
  });

  testWidgets('contador mostra 0/300 inicialmente', (tester) async {
    await montarWidget(tester);

    expect(find.text('0/300'), findsOneWidget);
  });

  testWidgets('contador atualiza conforme digitacao', (tester) async {
    await montarWidget(tester);

    await tester.enterText(find.byType(TextField), 'Pescador de rio');
    await tester.pump();

    expect(find.text('15/300'), findsOneWidget);
  });

  testWidgets('contador fica vermelho quando atinge o limite', (
    tester,
  ) async {
    await montarWidget(tester);
    final colors = AppColors.light;

    final texto300 = 'a' * 300;
    await tester.enterText(find.byType(TextField), texto300);
    await tester.pump();

    final contador = tester.widget<Text>(find.text('300/300'));
    expect(contador.style?.color, colors.danger);
  });

  testWidgets('link pular esta etapa e renderizado', (tester) async {
    await montarWidget(tester);

    expect(find.byType(OnboardingLinkPular), findsOneWidget);
    expect(find.text('Pular esta etapa'), findsOneWidget);
  });
}
