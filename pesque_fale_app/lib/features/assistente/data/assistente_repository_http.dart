import '../domain/mensagem_assistente.dart';
import 'assistente_api_client.dart';
import 'assistente_exceptions.dart';
import 'assistente_repository.dart';

class AssistenteRepositoryHttp implements AssistenteRepository {
  AssistenteRepositoryHttp({required this.apiClient});

  final AssistenteApiClient apiClient;

  @override
  Future<RespostaAssistente> perguntar({
    required String mensagem,
    required List<MensagemAssistente> historico,
    String? tela,
  }) async {
    final json = await apiClient.perguntar(
      mensagem: mensagem,
      historico: historico.map((m) => m.toHistorico()).toList(),
      tela: tela,
    );
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const InternalServerException();
    }
    final resposta = RespostaAssistente.fromJson(data);
    if (resposta.resposta.isEmpty) {
      throw const InternalServerException();
    }
    return resposta;
  }
}