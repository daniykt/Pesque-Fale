class DadosEvento {
  const DadosEvento({
    required this.titulo,
    this.descricao,
    required this.dataInicio,
    this.dataFim,
    this.localTexto,
    this.pontoId,
    this.imagemUrl,
  });

  final String titulo;
  final String? descricao;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final String? localTexto;
  final String? pontoId;
  final String? imagemUrl;

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'descricao': descricao,
    'dataInicio': dataInicio.toUtc().toIso8601String(),
    'dataFim': dataFim?.toUtc().toIso8601String(),
    'localTexto': localTexto,
    'pontoId': pontoId,
    'imagemUrl': imagemUrl,
  };
}
