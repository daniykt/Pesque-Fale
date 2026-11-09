enum TipoPonto {
  rio('rio', 'Rio'),
  lago('lago', 'Lago'),
  mar('mar', 'Mar'),
  represa('represa', 'Represa'),
  pesqueiro('pesqueiro', 'Pesqueiro');

  const TipoPonto(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TipoPonto? fromApi(String? v) {
    if (v == null) return null;
    for (final tipo in TipoPonto.values) {
      if (tipo.apiValue == v) return tipo;
    }
    return null;
  }
}
