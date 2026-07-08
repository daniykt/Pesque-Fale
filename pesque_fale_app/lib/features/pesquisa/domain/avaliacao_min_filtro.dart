enum AvaliacaoMinFiltro {
  todas(null, 'Todas'),
  tres(3.0, '≥ 3 estrelas'),
  quatro(4.0, '≥ 4 estrelas'),
  quatroMeio(4.5, '≥ 4.5 estrelas');

  const AvaliacaoMinFiltro(this.valor, this.label);

  final double? valor;
  final String label;
}
