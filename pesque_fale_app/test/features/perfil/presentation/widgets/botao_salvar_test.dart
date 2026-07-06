import 'dart:async';
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
import 'package:pesque_fale_app/features/perfil/presentation/editar_perfil/widgets/botao_salvar.dart';
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
        onboardingConcluido: true,
      ),
    );
  }

  @override
  Future<void> logout() async {}
}

class _FakePerfilRepository implements PerfilRepository {
  _FakePerfilRepository({this.delay = Duration.zero});

  final Duration delay;

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
    await Future.delayed(delay);
    return const Usuario(
      id: '1',
      nome: 'Ana Editada',
      email: 'ana@teste.com',
      onboardingConcluido: true,
    );
  }

  @override
  Future<bool> verificarUsername(String username) async => true;
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<EditarPerfilProvider> montarWidget(
    WidgetTester tester, {
    Duration delay = Duration.zero,
  }) async {
    final authProvider = AuthProvider(repository: _FakeAuthRepository());
    await authProvider.login(email: 'ana@teste.com', senha: '123456');

    late EditarPerfilProvider editarProvider;

    await tester.pumpWidget(
      ChangeNotifierProvider<EditarPerfilProvider>(
        create: (_) {
          editarProvider = EditarPerfilProvider(
            repository: _FakePerfilRepository(delay: delay),
            authProvider: authProvider,
          );
          return editarProvider;
        },
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: BotaoSalvar()),
        ),
      ),
    );
    await tester.pump();
    return editarProvider;
  }

  testWidgets('estado idle mostra "Salvar Alterações"', (tester) async {
    await montarWidget(tester);

    expect(find.text('Salvar Alterações'), findsOneWidget);
  });

  testWidgets('estado salvando mostra spinner e desabilita o botao', (
    tester,
  ) async {
    final provider = await montarWidget(
      tester,
      delay: const Duration(milliseconds: 300),
    );
    provider.onNomeChanged('Ana Editada');
    await tester.pump();

    unawaited(provider.salvar());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.pump(const Duration(milliseconds: 350));
  });

  testWidgets('estado salvo mostra check verde e "Salvo!"', (tester) async {
    final provider = await montarWidget(tester);
    provider.onNomeChanged('Ana Editada');
    await tester.pump();

    unawaited(provider.salvar());
    await tester.pumpAndSettle();

    expect(find.text('Salvo!'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
