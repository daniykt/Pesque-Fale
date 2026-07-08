class Avaliacao {
  const Avaliacao({
    required this.id,
    required this.usuarioId,
    required this.usuarioNome,
    required this.usuarioUsername,
    this.usuarioFoto,
    required this.pontoId,
    required this.nota,
    this.comentario,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  final String id;
  final String usuarioId;
  final String usuarioNome;
  final String usuarioUsername;
  final String? usuarioFoto;
  final String pontoId;
  final double nota;
  final String? comentario;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  bool get foiEditada =>
      atualizadoEm.isAfter(criadoEm.add(const Duration(seconds: 5)));

  factory Avaliacao.fromJson(Map<String, dynamic> json) {
    return Avaliacao(
      id: json['id']?.toString() ?? '',
      usuarioId: json['usuarioId']?.toString() ?? '',
      usuarioNome: json['usuarioNome']?.toString() ?? '',
      usuarioUsername: json['usuarioUsername']?.toString() ?? '',
      usuarioFoto: json['usuarioFoto'] as String?,
      pontoId: json['pontoId']?.toString() ?? '',
      nota: (json['nota'] as num?)?.toDouble() ?? 0,
      comentario: json['comentario'] as String?,
      criadoEm: DateTime.tryParse(json['criadoEm']?.toString() ?? '') ??
          DateTime.now(),
      atualizadoEm:
          DateTime.tryParse(json['atualizadoEm']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}
