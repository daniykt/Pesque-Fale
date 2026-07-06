class Publicacao {
  const Publicacao({
    required this.id,
    required this.autorId,
    required this.imagemUrl,
    this.legenda,
    this.tags = const [],
    this.curtidasCount = 0,
    this.comentariosCount = 0,
    this.criadoEm,
  });

  final String id;
  final String autorId;
  final String imagemUrl;
  final String? legenda;
  final List<String> tags;
  final int curtidasCount;
  final int comentariosCount;
  final String? criadoEm;

  factory Publicacao.fromJson(Map<String, dynamic> json) {
    return Publicacao(
      id: json['id']?.toString() ?? '',
      autorId: json['autorId']?.toString() ?? '',
      imagemUrl: json['imagemUrl']?.toString() ?? '',
      legenda: json['legenda'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      curtidasCount: json['curtidasCount'] as int? ?? 0,
      comentariosCount: json['comentariosCount'] as int? ?? 0,
      criadoEm: json['criadoEm']?.toString(),
    );
  }
}
