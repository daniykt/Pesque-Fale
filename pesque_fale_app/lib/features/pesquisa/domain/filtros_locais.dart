import 'avaliacao_min_filtro.dart';
import 'tipo_ponto.dart';

class FiltrosLocais {
  const FiltrosLocais({
    this.busca = '',
    this.tipo,
    this.avaliacaoMin = AvaliacaoMinFiltro.todas,
    this.raioKm = 50,
  });

  final String busca;

  /// `null` representa "Todos os tipos".
  final TipoPonto? tipo;
  final AvaliacaoMinFiltro avaliacaoMin;

  /// Só usado no modo Mapa.
  final double raioKm;

  FiltrosLocais copyWith({
    String? busca,
    TipoPonto? Function()? tipo,
    AvaliacaoMinFiltro? avaliacaoMin,
    double? raioKm,
  }) {
    return FiltrosLocais(
      busca: busca ?? this.busca,
      tipo: tipo != null ? tipo() : this.tipo,
      avaliacaoMin: avaliacaoMin ?? this.avaliacaoMin,
      raioKm: raioKm ?? this.raioKm,
    );
  }
}
