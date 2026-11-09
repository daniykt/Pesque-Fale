class Comentario {
  const Comentario({
    required this.id,
    required this.publicacaoId,
    required this.autorId,
    required this.autorNome,
    this.autorUsername,
    this.autorFoto,
    required this.texto,
    required this.criadoEm,
    this.enviando = false,
  });

  final String id;
  final String publicacaoId;
  final String autorId;
  final String autorNome;
  final String? autorUsername;
  final String? autorFoto;
  final String texto;
  final DateTime criadoEm;

  /// `true` enquanto o comentário criado otimisticamente ainda não foi
  /// confirmado pelo servidor.
  final bool enviando;

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id']?.toString() ?? '',
      publicacaoId: json['publicacaoId']?.toString() ?? '',
      autorId: json['autorId']?.toString() ?? '',
      autorNome: json['autorNome']?.toString() ?? '',
      autorUsername: json['autorUsername'] as String?,
      autorFoto: json['autorFoto'] as String?,
      texto: json['texto']?.toString() ?? '',
      criadoEm:
          DateTime.tryParse(json['criadoEm']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Comentario copyWith({bool? enviando}) {
    return Comentario(
      id: id,
      publicacaoId: publicacaoId,
      autorId: autorId,
      autorNome: autorNome,
      autorUsername: autorUsername,
      autorFoto: autorFoto,
      texto: texto,
      criadoEm: criadoEm,
      enviando: enviando ?? this.enviando,
    );
  }
}
