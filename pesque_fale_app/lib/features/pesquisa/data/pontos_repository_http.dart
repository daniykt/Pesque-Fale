import '../domain/filtros_locais.dart';
import '../domain/ponto.dart';
import 'pontos_api_client.dart';
import 'pontos_repository.dart';

class PontosRepositoryHttp implements PontosRepository {
  PontosRepositoryHttp({required this.apiClient});

  final PontosApiClient apiClient;

  @override
  Future<List<Ponto>> buscar({
    required FiltrosLocais filtros,
    double? lat,
    double? lng,
    bool incluirDistancia = false,
  }) {
    final queryParams = <String, String>{'porPagina': '50'};

    if (filtros.busca.isNotEmpty) queryParams['busca'] = filtros.busca;
    if (filtros.tipo != null) queryParams['tipo'] = filtros.tipo!.apiValue;
    if (filtros.avaliacaoMin.valor != null) {
      queryParams['avaliacaoMin'] = filtros.avaliacaoMin.valor.toString();
    }
    if (lat != null && lng != null) {
      queryParams['lat'] = lat.toString();
      queryParams['lng'] = lng.toString();
      if (incluirDistancia) {
        queryParams['raio'] = filtros.raioKm.toString();
      }
    }

    return apiClient.buscar(queryParams);
  }
}
