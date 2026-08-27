import '../domain/conversa.dart';
import 'conversas_api_client.dart';
import 'conversas_repository.dart';

class ConversasRepositoryHttp implements ConversasRepository {
  ConversasRepositoryHttp({required this.apiClient});

  final ConversasApiClient apiClient;

  @override
  Future<List<Conversa>> listar() async {
    final json = await apiClient.listar();
    final data = (json['data'] as List<dynamic>?) ?? const [];
    return data
        .map((e) => Conversa.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
