import '../../../core/data/paged_result.dart';
import '../domain/comentario.dart';
import 'comentarios_api_client.dart';
import 'comentarios_repository.dart';

class ComentariosRepositoryHttp implements ComentariosRepository {
  ComentariosRepositoryHttp({required this.apiClient});

  final ComentariosApiClient apiClient;

  @override
  Future<PagedResult<Comentario>> listar(
    String publicacaoId, {
    int pagina = 1,
    int porPagina = 20,
  }) async {
    final json = await apiClient.listar(
      publicacaoId,
      pagina: pagina,
      porPagina: porPagina,
    );
    final data = (json['data'] as List<dynamic>?) ?? const [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return PagedResult(
      items: data
          .map((e) => Comentario.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: meta['total'] as int? ?? 0,
      pagina: meta['pagina'] as int? ?? pagina,
      porPagina: meta['porPagina'] as int? ?? porPagina,
    );
  }

  @override
  Future<Comentario> criar(String publicacaoId, String texto) async {
    final json = await apiClient.criar(publicacaoId, texto);
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return Comentario.fromJson(data);
  }

  @override
  Future<void> deletar(String comentarioId) => apiClient.deletar(comentarioId);
}
