import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_exceptions.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository.dart';
import 'package:pesque_fale_app/features/perfil/domain/perfil_completo.dart';
import 'package:pesque_fale_app/features/perfil/providers/perfil_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async {
    return const AuthResult(
      accessToken: 'token',
      usuario: Usuario(
        id: 'eu',
        nome: 'Eu Mesmo',
        email: 'eu@teste.com',
        onboardingConcluido: true,
      ),
    );
  }

  @override
  Future<void> logout() async {}
}

class _FakePerfilRepository implements PerfilRepository {
  _FakePerfilRepository({this.falharAoSeguir = false});

  final bool falharAoSeguir;

  final _outro = const Usuario(
    id: 'outro',
    nome: 'Outro Pescador',
    email: 'outro@teste.com',
    onboardingConcluido: true,
    seguidores: 10,
  );

  @override
  Future<PerfilCompleto> buscarPerfil(
    String id, {
    required String meuId,
  }) async {
    return PerfilCompleto(usuario: _outro, publicacoes: const []);
  }

  @override
  Future<void> seguir(String id) async {
    if (falharAoSeguir) throw const InternalServerException();
  }

  @override
  Future<void> deixarDeSeguir(String id) async {
    if (falharAoSeguir) throw const InternalServerException();
  }

  @override
  Future<String> atualizarFoto(File arquivo) async => 'https://x/foto.png';

  @override
  Future<String> atualizarBanner(File arquivo) async => 'https://x/banner.png';
}

void main() {
  late AuthProvider authProvider;

  setUp(() async {
    authProvider = AuthProvider(repository: _FakeAuthRepository());
    await authProvider.login(email: 'eu@teste.com', senha: '123456');
  });

  group('PerfilProvider.carregarPerfil', () {
    test('hidrata perfil e publicacoes com sucesso', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(),
        authProvider: authProvider,
      );

      await provider.carregarPerfil('outro');

      expect(provider.status, PerfilStatus.success);
      expect(provider.perfil?.id, 'outro');
      expect(provider.isOwnProfile, isFalse);
    });
  });

  group('PerfilProvider.seguir', () {
    test('atualiza otimisticamente e mantém em caso de sucesso', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(),
        authProvider: authProvider,
      );
      await provider.carregarPerfil('outro');

      final ok = await provider.seguir();

      expect(ok, isTrue);
      expect(provider.isFollowing, isTrue);
      expect(provider.perfil?.seguidores, 11);
    });

    test(
      'faz rollback do estado e do contador quando a chamada falha',
      () async {
        final provider = PerfilProvider(
          repository: _FakePerfilRepository(falharAoSeguir: true),
          authProvider: authProvider,
        );
        await provider.carregarPerfil('outro');

        final ok = await provider.seguir();

        expect(ok, isFalse);
        expect(provider.isFollowing, isFalse);
        expect(provider.perfil?.seguidores, 10);
        expect(provider.errorMessage, isNotNull);
      },
    );
  });

  group('PerfilProvider.abrirChat', () {
    test('gera chatId ordenado independente da ordem dos ids', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(),
        authProvider: authProvider,
      );
      await provider.carregarPerfil('outro');

      expect(provider.abrirChat(), 'eu_outro');
    });
  });
}
