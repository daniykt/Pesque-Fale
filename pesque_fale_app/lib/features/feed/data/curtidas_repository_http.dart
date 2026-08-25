import 'curtidas_api_client.dart';
import 'curtidas_repository.dart';

class CurtidasRepositoryHttp implements CurtidasRepository {
  CurtidasRepositoryHttp({required this.apiClient});

  final CurtidasApiClient apiClient;

  @override
  Future<void> curtir(String publicacaoId) => apiClient.curtir(publicacaoId);

  @override
  Future<void> descurtir(String publicacaoId) =>
      apiClient.descurtir(publicacaoId);
}
