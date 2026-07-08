import '../domain/filtros_locais.dart';
import '../domain/ponto.dart';

abstract class PontosRepository {
  /// Busca pontos de pesca aplicando [filtros].
  ///
  /// [lat]/[lng] só são enviados quando [incluirDistancia] é `true` (modo
  /// Mapa) — nesse caso o raio de [filtros] também é considerado.
  Future<List<Ponto>> buscar({
    required FiltrosLocais filtros,
    double? lat,
    double? lng,
    bool incluirDistancia = false,
  });
}
