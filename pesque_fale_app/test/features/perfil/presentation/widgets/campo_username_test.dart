import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository.dart';
import 'package:pesque_fale_app/features/perfil/domain/perfil_completo.dart';
import 'package:pesque_fale_app/features/perfil/presentation/editar_perfil/widgets/campo_username.dart';
import 'package:pesque_fale_app/features/perfil/providers/editar_perfil_provider.dart';

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
        username: 'ana_original',
        onboardingConcluido: true,
      ),
    );
  }

  @override
  Future<void> logout() async {}
}

class _FakePerfilRepository implements PerfilRepository {
  final Set<String> usernamesIndisponiveis = {'ocupado'};

  @override
  Future<PerfilCompleto> buscarPerfil(String id, {required String meuId}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> seguir(String id) async {}

  @override
  Future<void> deixarDeSeguir(String id) async {}

  @override
  Future<String> atualizarFoto(File arquivo) async => '';

  @override
  Future<String> atualizarBanner(File arquivo) async => '';

  @override
  Future<Usuario> editarPerfil(Map<String, dynamic> camposAlterados) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> verificarUsername(String username) async {
    return !usernamesIndisponiveis.contains(username);
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<EditarPerfilProvider> montarWidget(WidgetTester tester) async {
    final authProvider = AuthProvider(repository: _FakeAuthRepository());
    await authProvider.login(email: 'ana@teste.com', senha: '123456');

    late EditarPerfilProvider editarProvider;

    await tester.pumpWidget(
      ChangeNotifierProvider<EditarPerfilProvider>(
        create: (_) {
          editarProvider = EditarPerfilProvider(
            repository: _FakePerfilRepository(),
            authProvider: authProvider,
          );
          return editarProvider;
        },
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: CampoUsername()),
        ),
      ),
    );
    await tester.pump();
    return editarProvider;
  }

  testWidgets('estado atual exibido quando username nao muda', (tester) async {
    await montarWidget(tester);

    expect(find.text('Username atual'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('estado invalidoFormato exibido sem chamar a API', (tester) async {
    final provider = await montarWidget(tester);

    provider.onUsernameChanged('ab');
    await tester.pump();

    expect(find.text('3-20 caracteres. Use letras, números, _ ou .'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('estado validating exibido logo apos digitar valor valido', (tester) async {
    final provider = await montarWidget(tester);

    provider.onUsernameChanged('livre123');
    await tester.pump();

    expect(find.text('Verificando...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('estado disponivel exibido apos o debounce resolver', (tester) async {
    final provider = await montarWidget(tester);

    provider.onUsernameChanged('livre123');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Disponível'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('estado indisponivel exibido quando a API recusa', (tester) async {
    final provider = await montarWidget(tester);

    provider.onUsernameChanged('ocupado');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Já em uso'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
  });

  testWidgets('estado idle nao exibe icone nem texto quando username original é vazio', (tester) async {
    final authProvider = AuthProvider(repository: _FakeAuthRepository());
    await authProvider.login(email: 'ana@teste.com', senha: '123456');
    authProvider.atualizarUsuario(authProvider.usuario!.copyWith(username: ''));

    await tester.pumpWidget(
      ChangeNotifierProvider<EditarPerfilProvider>(
        create: (_) => EditarPerfilProvider(
          repository: _FakePerfilRepository(),
          authProvider: authProvider,
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: CampoUsername()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Username atual'), findsNothing);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
  });
}
