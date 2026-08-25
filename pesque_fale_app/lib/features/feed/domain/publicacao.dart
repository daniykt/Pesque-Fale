class Publicacao {
  const Publicacao({
    required this.id,
    required this.autorId,
    required this.autorNome,
    this.autorUsername,
    this.autorFoto,
    this.pontoId,
    this.descricao,
    this.imagemUrl,
    this.localTexto,
    this.avaliacaoNota,
    this.tags = const [],
    this.curtidasCount = 0,
    this.comentariosCount = 0,
    this.jaCurtiu = false,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  final String id;
  final String autorId;
  final String autorNome;
  final String? autorUsername;
  final String? autorFoto;
  final String? pontoId;
  final String? descricao;
  final String? imagemUrl;
  final String? localTexto;
  final double? avaliacaoNota;
  final List<String> tags;
  final int curtidasCount;
  final int comentariosCount;
  final bool jaCurtiu;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  factory Publicacao.fromJson(Map<String, dynamic> json) {
    return Publicacao(
      id: json['id']?.toString() ?? '',
      autorId: json['autorId']?.toString() ?? '',
      autorNome: json['autorNome']?.toString() ?? '',
      autorUsername: json['autorUsername'] as String?,
      autorFoto: json['autorFoto'] as String?,
      pontoId: json['pontoId'] as String?,
      descricao: json['descricao'] as String?,
      imagemUrl: json['imagemUrl'] as String?,
      localTexto: json['localTexto'] as String?,
      avaliacaoNota: (json['avaliacaoNota'] as num?)?.toDouble(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      curtidasCount: json['curtidasCount'] as int? ?? 0,
      comentariosCount: json['comentariosCount'] as int? ?? 0,
      jaCurtiu: json['jaCurtiu'] as bool? ?? false,
      criadoEm:
          DateTime.tryParse(json['criadoEm']?.toString() ?? '') ??
          DateTime.now(),
      atualizadoEm:
          DateTime.tryParse(json['atualizadoEm']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Publicacao copyWith({
    String? descricao,
    String? imagemUrl,
    String? localTexto,
    double? avaliacaoNota,
    List<String>? tags,
    int? curtidasCount,
    int? comentariosCount,
    bool? jaCurtiu,
  }) {
    return Publicacao(
      id: id,
      autorId: autorId,
      autorNome: autorNome,
      autorUsername: autorUsername,
      autorFoto: autorFoto,
      pontoId: pontoId,
      descricao: descricao ?? this.descricao,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      localTexto: localTexto ?? this.localTexto,
      avaliacaoNota: avaliacaoNota ?? this.avaliacaoNota,
      tags: tags ?? this.tags,
      curtidasCount: curtidasCount ?? this.curtidasCount,
      comentariosCount: comentariosCount ?? this.comentariosCount,
      jaCurtiu: jaCurtiu ?? this.jaCurtiu,
      criadoEm: criadoEm,
      atualizadoEm: atualizadoEm,
    );
  }
}
