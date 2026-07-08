import 'tipo_ponto.dart';

class Ponto {
  const Ponto({
    required this.id,
    required this.nome,
    this.descricao,
    required this.latitude,
    required this.longitude,
    required this.cidade,
    required this.estado,
    required this.tipo,
    this.fotoCapa,
    this.fotos = const [],
    this.tags = const [],
    this.avgNota = 0,
    this.totalAvaliacoes = 0,
    this.distanciaKm,
    required this.criadoPor,
    this.criadoEm,
  });

  final String id;
  final String nome;
  final String? descricao;
  final double latitude;
  final double longitude;
  final String cidade;
  final String estado;
  final TipoPonto tipo;
  final String? fotoCapa;
  final List<String> fotos;
  final List<String> tags;
  final double avgNota;
  final int totalAvaliacoes;
  final double? distanciaKm;
  final String criadoPor;
  final String? criadoEm;

  factory Ponto.fromJson(Map<String, dynamic> json) {
    return Ponto(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      cidade: json['cidade']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      tipo: TipoPonto.fromApi(json['tipo'] as String?) ?? TipoPonto.pesqueiro,
      fotoCapa: json['fotoCapa'] as String?,
      fotos:
          (json['fotos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      avgNota: (json['avgNota'] as num?)?.toDouble() ?? 0,
      totalAvaliacoes: json['totalAvaliacoes'] as int? ?? 0,
      distanciaKm: (json['distanciaKm'] as num?)?.toDouble(),
      criadoPor: json['criadoPor']?.toString() ?? '',
      criadoEm: json['criadoEm']?.toString(),
    );
  }
}
