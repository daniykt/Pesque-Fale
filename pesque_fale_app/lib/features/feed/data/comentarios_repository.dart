import '../../../core/data/paged_result.dart';
import '../domain/comentario.dart';

abstract class ComentariosRepository {
  Future<PagedResult<Comentario>> listar(
    String publicacaoId, {
    int pagina = 1,
    int porPagina = 20,
  });

  Future<Comentario> criar(String publicacaoId, String texto);

  Future<void> deletar(String comentarioId);
}
