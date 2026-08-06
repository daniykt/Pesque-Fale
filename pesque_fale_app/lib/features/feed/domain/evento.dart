class Evento {
  const Evento({
    required this.id,
    required this.titulo,
    this.descricao,
    this.pontoId,
    required this.organizadorId,
    required this.organizadorNome,
    this.organizadorFoto,
    required this.dataInicio,
    this.dataFim,
    this.imagemUrl,
    this.localTexto,
    required this.criadoEm,
  });

  final String id;
  final String titulo;
  final String? descricao;
  final String? pontoId;
  final String organizadorId;
  final String organizadorNome;
  final String? organizadorFoto;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final String? imagemUrl;
  final String? localTexto;
  final DateTime criadoEm;

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      descricao: json['descricao'] as String?,
      pontoId: json['pontoId'] as String?,
      organizadorId: json['organizadorId']?.toString() ?? '',
      organizadorNome: json['organizadorNome']?.toString() ?? '',
      organizadorFoto: json['organizadorFoto'] as String?,
      dataInicio:
          DateTime.tryParse(json['dataInicio']?.toString() ?? '') ??
          DateTime.now(),
      dataFim: json['dataFim'] != null
          ? DateTime.tryParse(json['dataFim'].toString())
          : null,
      imagemUrl: json['imagemUrl'] as String?,
      localTexto: json['localTexto'] as String?,
      criadoEm:
          DateTime.tryParse(json['criadoEm']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
