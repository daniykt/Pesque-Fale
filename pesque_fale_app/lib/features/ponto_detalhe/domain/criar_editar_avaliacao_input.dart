class CriarEditarAvaliacaoInput {
  const CriarEditarAvaliacaoInput({required this.nota, this.comentario});

  final double nota;
  final String? comentario;

  Map<String, dynamic> toJson() => {
    'nota': nota,
    if (comentario != null && comentario!.trim().isNotEmpty)
      'comentario': comentario!.trim(),
  };
}
