import '../domain/auth_result.dart';

abstract class AuthRepository {
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  });

  Future<AuthResult> login({required String email, required String senha});

  Future<void> logout();
}
