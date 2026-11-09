import '../domain/avaliacao.dart';
import '../domain/criar_editar_avaliacao_input.dart';
import 'avaliacoes_api_client.dart';
import 'avaliacoes_exceptions.dart';
import 'avaliacoes_repository.dart';

class AvaliacoesRepositoryHttp implements AvaliacoesRepository {
  AvaliacoesRepositoryHttp({required this.apiClient});

  final AvaliacoesApiClient apiClient;

  @override
  Future<List<Avaliacao>> listar(
    String pontoId, {
    int pagina = 1,
    int porPagina = 20,
  }) async {
    final json = await apiClient.listar(
      pontoId,
      pagina: pagina,
      porPagina: porPagina,
    );
    final data = (json['data'] as List<dynamic>?) ?? const [];
    return data
        .map((e) => Avaliacao.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Avaliacao?> minhaAvaliacao(String pontoId) async {
    try {
      final json = await apiClient.minhaAvaliacao(pontoId);
      return Avaliacao.fromJson(json);
    } on AvaliacaoNaoEncontradaException {
      return null;
    }
  }

  @override
  Future<Avaliacao> criar(
    String pontoId,
    CriarEditarAvaliacaoInput input,
  ) async {
    final json = await apiClient.criar(pontoId, input.toJson());
    return Avaliacao.fromJson(json);
  }

  @override
  Future<Avaliacao> editar(
    String pontoId,
    CriarEditarAvaliacaoInput input,
  ) async {
    final json = await apiClient.editar(pontoId, input.toJson());
    return Avaliacao.fromJson(json);
  }

  @override
  Future<void> deletar(String pontoId) => apiClient.deletar(pontoId);
}
