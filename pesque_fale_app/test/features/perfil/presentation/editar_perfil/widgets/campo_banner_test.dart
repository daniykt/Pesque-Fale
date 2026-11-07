import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_api_client.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository.dart';
import 'package:pesque_fale_app/features/perfil/domain/perfil_completo.dart';
import 'package:pesque_fale_app/features/perfil/presentation/editar_perfil/widgets/campo_banner.dart';
import 'package:pesque_fale_app/features/perfil/providers/editar_perfil_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.banner});

  final String? banner;

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
        nome: 'Ana',
        email: 'ana@teste.com',
        onboardingConcluido: true,
        banner: banner,
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
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> seguir(String id) async {}

  @override
  Future<void> deixarDeSeguir(String id) async {}

  @override
  Future<String> atualizarFoto(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async => '';

  @override
  Future<String> atualizarBanner(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async => '';

  @override
  Future<Usuario> editarPerfil(Map<String, dynamic> camposAlterados) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> verificarUsername(String username) async => true;

  @override
  Future<ListaPaginada<UsuarioResumido>> buscarSeguidores(
    String id, {
    int pagina = 1,
    int porPagina = 20,
  }) async => throw UnimplementedError();

  @override
  Future<ListaPaginada<UsuarioResumido>> buscarSeguindo(
    String id, {
    int pagina = 1,
    int porPagina = 20,
  }) async => throw UnimplementedError();
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const bannerPadrao = ValueKey('banner-padrao');

  Future<void> montar(
    WidgetTester tester, {
    required ThemeData Function() tema,
    String? banner,
  }) async {
    final authProvider = AuthProvider(
      repository: _FakeAuthRepository(banner: banner),
    );
    await authProvider.login(email: 'ana@teste.com', senha: '123456');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<EditarPerfilProvider>(
            create: (_) => EditarPerfilProvider(
              repository: _FakePerfilRepository(),
              authProvider: authProvider,
            ),
          ),
        ],
        child: MaterialApp(
          theme: tema(),
          home: const Scaffold(body: CampoBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (nomeTema, tema) in [
    ('claro', () => AppTheme.light),
    ('escuro', () => AppTheme.dark),
  ]) {
    testWidgets(
      'banner inválido ("[BANNER]") cai no gradiente padrão (tema $nomeTema)',
      (tester) async {
        await montar(tester, tema: tema, banner: '[BANNER]');

        expect(tester.takeException(), isNull);
        expect(find.byKey(bannerPadrao), findsOneWidget);
      },
    );

    testWidgets('sem banner mostra o gradiente padrão (tema $nomeTema)', (
      tester,
    ) async {
      await montar(tester, tema: tema);

      expect(tester.takeException(), isNull);
      expect(find.byKey(bannerPadrao), findsOneWidget);
    });
  }
}
