import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';

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
        id: '1',
        nome: 'Pescador',
        email: 'pescador@teste.com',
        onboardingConcluido: true,
      ),
    );
  }

  @override
  Future<void> logout() async {}
}

void main() {
  group('AuthProvider.atualizarUsuario', () {
    test('substitui o usuario compartilhado e notifica listeners', () async {
      final provider = AuthProvider(repository: _FakeAuthRepository());
      await provider.login(email: 'pescador@teste.com', senha: '123456');

      var notificado = false;
      provider.addListener(() => notificado = true);

      final atualizado = provider.usuario!.copyWith(
        nome: 'Novo Nome',
        bio: 'Bio nova',
      );
      provider.atualizarUsuario(atualizado);

      expect(provider.usuario?.nome, 'Novo Nome');
      expect(provider.usuario?.bio, 'Bio nova');
      expect(notificado, isTrue);
    });
  });
}
