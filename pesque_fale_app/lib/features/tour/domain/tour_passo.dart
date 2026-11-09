/// Um passo do tour guiado exibido após o onboarding.
class TourPasso {
  const TourPasso({
    required this.index,
    required this.titulo,
    required this.descricao,
    required this.abaAlvo,
  });

  /// Posição do passo no roteiro (0-based).
  final int index;

  final String titulo;

  final String descricao;

  /// Índice da aba principal (bottom nav) que deve ficar ativa neste passo.
  final int abaAlvo;
}
