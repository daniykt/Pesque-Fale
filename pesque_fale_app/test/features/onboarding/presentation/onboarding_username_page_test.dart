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
import 'package:pesque_fale_app/features/onboarding/presentation/etapas/onboarding_username_page.dart';
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
  final Set<String> usernamesIndisponiveis = {'ocupado'};

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
  Future<bool> verificarUsername(String username) async {
    return !usernamesIndisponiveis.contains(username);
  }
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
          home: const OnboardingUsernamePage(),
        ),
      ),
    );
    await tester.pump();
    return onboardingProvider;
  }

  testWidgets('estado idle nao renderiza chip e botao fica desabilitado', (
    tester,
  ) async {
    await montarWidget(tester);

    expect(find.text('Verificando...'), findsNothing);
    expect(find.text('✅ Disponível'), findsNothing);
    final botao = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(botao.onPressed, isNull);
  });

  testWidgets('estado validating mostra spinner e Verificando..., botao desabilitado', (
    tester,
  ) async {
    await montarWidget(tester);

    await tester.enterText(find.byType(TextField), 'livre123');
    await tester.pump();

    expect(find.text('Verificando...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final botao = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(botao.onPressed, isNull);

    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('estado invalidoFormato mostra mensagem de formato, botao desabilitado', (
    tester,
  ) async {
    await montarWidget(tester);

    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pump();

    expect(
      find.text('3-20 caracteres. Use letras, números, _ ou .'),
      findsOneWidget,
    );
    final botao = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(botao.onPressed, isNull);
  });

  testWidgets('estado indisponivel mostra Ja em uso, botao desabilitado', (
    tester,
  ) async {
    await montarWidget(tester);

    await tester.enterText(find.byType(TextField), 'ocupado');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Já em uso'), findsOneWidget);
    final botao = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(botao.onPressed, isNull);
  });

  testWidgets('estado disponivel mostra chip verde e habilita o botao', (
    tester,
  ) async {
    await montarWidget(tester);

    await tester.enterText(find.byType(TextField), 'livre123');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('✅ Disponível'), findsOneWidget);
    final botao = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(botao.onPressed, isNotNull);
  });

  testWidgets('nao renderiza link de pular esta etapa', (tester) async {
    await montarWidget(tester);

    expect(find.byType(OnboardingLinkPular), findsNothing);
    expect(find.text('Pular esta etapa'), findsNothing);
  });

  testWidgets('digitacao chama onUsernameChanged', (tester) async {
    final provider = await montarWidget(tester);

    await tester.enterText(find.byType(TextField), 'joao_pescador');
    await tester.pump();

    expect(provider.username, 'joao_pescador');
    await tester.pump(const Duration(milliseconds: 600));
  });
}
