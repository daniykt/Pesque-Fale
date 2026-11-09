import '../domain/avaliacao.dart';
import '../domain/criar_editar_avaliacao_input.dart';

abstract class AvaliacoesRepository {
  Future<List<Avaliacao>> listar(
    String pontoId, {
    int pagina = 1,
    int porPagina = 20,
  });

  /// Retorna `null` quando o usuário logado ainda não avaliou o ponto.
  Future<Avaliacao?> minhaAvaliacao(String pontoId);

  Future<Avaliacao> criar(String pontoId, CriarEditarAvaliacaoInput input);

  Future<Avaliacao> editar(String pontoId, CriarEditarAvaliacaoInput input);

  Future<void> deletar(String pontoId);
}
