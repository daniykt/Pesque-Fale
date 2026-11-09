import '../domain/auth_result.dart';
import 'auth_api_client.dart';
import 'auth_repository.dart';
import 'token_storage.dart';

class AuthRepositoryHttp implements AuthRepository {
  AuthRepositoryHttp({required this.apiClient, required this.tokenStorage});

  final AuthApiClient apiClient;
  final TokenStorage tokenStorage;

  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async {
    final result = await apiClient.cadastrar(
      nome: nome,
      email: email,
      senha: senha,
      confirmarSenha: confirmarSenha,
    );
    await tokenStorage.saveToken(result.accessToken);
    return result;
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async {
    final result = await apiClient.login(email: email, senha: senha);
    await tokenStorage.saveToken(result.accessToken);
    return result;
  }

  @override
  Future<void> logout() => tokenStorage.clearToken();
}
