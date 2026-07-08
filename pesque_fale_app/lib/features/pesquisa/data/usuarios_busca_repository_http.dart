import '../domain/usuario_resumo.dart';
import 'usuarios_busca_api_client.dart';
import 'usuarios_busca_repository.dart';

class UsuariosBuscaRepositoryHttp implements UsuariosBuscaRepository {
  UsuariosBuscaRepositoryHttp({required this.apiClient});

  final UsuariosBuscaApiClient apiClient;

  @override
  Future<List<UsuarioResumo>> buscar(String texto) {
    if (texto.trim().isEmpty) return Future.value(const []);
    return apiClient.buscar(texto.trim());
  }
}
