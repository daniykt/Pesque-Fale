enum TagPublicacao {
  rio('Rio'),
  lago('Lago'),
  represa('Represa'),
  mar('Mar'),
  pescaEsportiva('Pesca Esportiva'),
  pescaNoturna('Pesca Noturna'),
  pescaDeFundo('Pesca de Fundo'),
  iniciante('Iniciante'),
  familia('Família');

  const TagPublicacao(this.label);
  final String label;
}
