import '../domain/auth_result.dart';
import '../domain/usuario.dart';
import 'auth_exceptions.dart';
import 'auth_repository.dart';
import 'token_storage.dart';

class AuthRepositoryMock implements AuthRepository {
  AuthRepositoryMock({required this.tokenStorage});

  final TokenStorage tokenStorage;

  static const _delay = Duration(milliseconds: 800);
  static const _emailExistente = 'existente@teste.com';
  static const _emailErro = 'erro@teste.com';

  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async {
    await Future.delayed(_delay);

    if (email == _emailExistente) {
      throw const EmailJaCadastradoException();
    }

    if (email == _emailErro) {
      throw const InternalServerException();
    }

    final result = AuthResult(
      accessToken: 'mock_access_token',
      usuario: Usuario(
        id: 'mock-id',
        nome: nome,
        email: email,
        onboardingConcluido: false,
      ),
    );
    await tokenStorage.saveToken(result.accessToken);
    return result;
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async {
    await Future.delayed(_delay);

    if (email == _emailErro) {
      throw const InternalServerException();
    }

    final result = AuthResult(
      accessToken: 'mock_access_token',
      usuario: Usuario(
        id: 'mock-id',
        nome: 'Usuário Mock',
        email: email,
        onboardingConcluido: false,
      ),
    );
    await tokenStorage.saveToken(result.accessToken);
    return result;
  }
}
