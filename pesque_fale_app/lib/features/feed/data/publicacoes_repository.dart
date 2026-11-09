import '../../../core/data/paged_result.dart';
import '../domain/publicacao.dart';

abstract class PublicacoesRepository {
  Future<PagedResult<Publicacao>> listar({
    int pagina = 1,
    int porPagina = 20,
    bool seguindo = false,
  });

  Future<Publicacao> buscarPorId(String id);

  Future<void> deletar(String id);

  Future<Publicacao> criar({
    String? descricao,
    String? imagemUrl,
    String? localTexto,
    double? avaliacaoNota,
    String? pontoId,
    List<String> tags = const [],
  });
}
