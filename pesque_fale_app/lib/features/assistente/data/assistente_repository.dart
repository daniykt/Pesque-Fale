import '../domain/mensagem_assistente.dart';

abstract class AssistenteRepository {
  Future<RespostaAssistente> perguntar({
    required String mensagem,
    required List<MensagemAssistente> historico,
    String? tela,
  });
}