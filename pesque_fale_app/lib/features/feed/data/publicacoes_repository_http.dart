import '../../../core/data/paged_result.dart';
import '../domain/publicacao.dart';
import 'publicacoes_api_client.dart';
import 'publicacoes_repository.dart';

class PublicacoesRepositoryHttp implements PublicacoesRepository {
  PublicacoesRepositoryHttp({required this.apiClient});

  final PublicacoesApiClient apiClient;

  @override
  Future<PagedResult<Publicacao>> listar({
    int pagina = 1,
    int porPagina = 20,
    bool seguindo = false,
  }) async {
    final json = await apiClient.listar(
      pagina: pagina,
      porPagina: porPagina,
      seguindo: seguindo,
    );
    final data = (json['data'] as List<dynamic>?) ?? const [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return PagedResult(
      items: data
          .map((e) => Publicacao.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: meta['total'] as int? ?? 0,
      pagina: meta['pagina'] as int? ?? pagina,
      porPagina: meta['porPagina'] as int? ?? porPagina,
    );
  }

  @override
  Future<Publicacao> buscarPorId(String id) async {
    final json = await apiClient.buscarPorId(id);
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return Publicacao.fromJson(data);
  }

  @override
  Future<void> deletar(String id) => apiClient.deletar(id);

  @override
  Future<Publicacao> criar({
    String? descricao,
    String? imagemUrl,
    String? localTexto,
    double? avaliacaoNota,
    String? pontoId,
    List<String> tags = const [],
  }) async {
    final json = await apiClient.criar({
      'descricao': ?descricao,
      'imagemUrl': ?imagemUrl,
      'localTexto': ?localTexto,
      'avaliacaoNota': ?avaliacaoNota,
      'pontoId': ?pontoId,
      'tags': tags,
    });
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return Publicacao.fromJson(data);
  }
}
