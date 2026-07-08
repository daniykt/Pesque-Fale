import 'dart:math';

import '../domain/filtros_locais.dart';
import '../domain/ponto.dart';
import '../domain/tipo_ponto.dart';
import 'pontos_repository.dart';

class PontosRepositoryMock implements PontosRepository {
  static const _delay = Duration(milliseconds: 400);

  static final List<Ponto> _pontos = [
    _ponto('1', 'Rio Mogi Guaçu', TipoPonto.rio, -21.9394, -47.1972, 'Mogi Guaçu', 'SP', 4.5, 32),
    _ponto('2', 'Lagoa do Taboão', TipoPonto.lago, -22.0087, -47.8909, 'Araraquara', 'SP', 3.8, 14),
    _ponto('3', 'Praia do Sunset', TipoPonto.mar, -23.9608, -46.3336, 'Guarujá', 'SP', 4.9, 58),
    _ponto('4', 'Represa de Ibitinga', TipoPonto.represa, -21.7566, -48.8283, 'Ibitinga', 'SP', 4.2, 21),
    _ponto('5', 'Pesqueiro Bom Retiro', TipoPonto.pesqueiro, -22.3145, -47.3005, 'Piracicaba', 'SP', 3.5, 9),
    _ponto('6', 'Rio Pardo', TipoPonto.rio, -21.1783, -47.8083, 'Ribeirão Preto', 'SP', 4.0, 17),
    _ponto('7', 'Lago Azul', TipoPonto.lago, -22.9099, -47.0626, 'Campinas', 'SP', 3.2, 6),
    _ponto('8', 'Praia Grande', TipoPonto.mar, -24.0058, -46.4025, 'Praia Grande', 'SP', 4.3, 40),
    _ponto('9', 'Represa Billings', TipoPonto.represa, -23.7714, -46.5964, 'São Bernardo do Campo', 'SP', 4.6, 47),
    _ponto('10', 'Pesqueiro Sítio Feliz', TipoPonto.pesqueiro, -22.4791, -47.6669, 'Rio Claro', 'SP', 2.9, 5),
    _ponto('11', 'Rio Tietê', TipoPonto.rio, -22.1256, -49.9284, 'Bauru', 'SP', 3.6, 11),
    _ponto('12', 'Lagoa Serena', TipoPonto.lago, -21.6082, -48.3658, 'São Carlos', 'SP', 4.8, 29),
    _ponto('13', 'Praia do Boqueirão', TipoPonto.mar, -24.3238, -47.0119, 'Cananéia', 'SP', 4.1, 18),
    _ponto('14', 'Represa do Jaguari', TipoPonto.represa, -23.0378, -46.0722, 'Jacareí', 'SP', 3.9, 13),
    _ponto('15', 'Pesqueiro Recanto Verde', TipoPonto.pesqueiro, -22.7253, -47.6492, 'Limeira', 'SP', 4.4, 24),
  ];

  static Ponto _ponto(
    String id,
    String nome,
    TipoPonto tipo,
    double lat,
    double lng,
    String cidade,
    String estado,
    double avgNota,
    int totalAvaliacoes,
  ) {
    return Ponto(
      id: id,
      nome: nome,
      descricao: 'Ótimo local para pescaria, com boa infraestrutura ao redor.',
      latitude: lat,
      longitude: lng,
      cidade: cidade,
      estado: estado,
      tipo: tipo,
      fotoCapa: 'https://picsum.photos/seed/ponto-$id/600/400',
      fotos: ['https://picsum.photos/seed/ponto-$id/600/400'],
      tags: const ['tilapia', 'tucunaré'],
      avgNota: avgNota,
      totalAvaliacoes: totalAvaliacoes,
      criadoPor: 'mock-id',
    );
  }

  @override
  Future<List<Ponto>> buscar({
    required FiltrosLocais filtros,
    double? lat,
    double? lng,
    bool incluirDistancia = false,
  }) async {
    await Future.delayed(_delay);

    var resultado = _pontos.where((p) {
      if (filtros.busca.isNotEmpty &&
          !p.nome.toLowerCase().contains(filtros.busca.toLowerCase())) {
        return false;
      }
      if (filtros.tipo != null && p.tipo != filtros.tipo) return false;
      if (filtros.avaliacaoMin.valor != null &&
          p.avgNota < filtros.avaliacaoMin.valor!) {
        return false;
      }
      return true;
    }).toList();

    if (incluirDistancia && lat != null && lng != null) {
      resultado = resultado
          .map((p) => _comDistancia(p, lat, lng))
          .where((p) => p.distanciaKm == null || p.distanciaKm! <= filtros.raioKm)
          .toList()
        ..sort((a, b) => (a.distanciaKm ?? 0).compareTo(b.distanciaKm ?? 0));
    }

    return resultado;
  }

  Ponto _comDistancia(Ponto p, double lat, double lng) {
    const raioTerraKm = 6371;
    final dLat = _grausParaRadianos(p.latitude - lat);
    final dLng = _grausParaRadianos(p.longitude - lng);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_grausParaRadianos(lat)) *
            cos(_grausParaRadianos(p.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distanciaKm = double.parse((raioTerraKm * c).toStringAsFixed(1));

    return Ponto(
      id: p.id,
      nome: p.nome,
      descricao: p.descricao,
      latitude: p.latitude,
      longitude: p.longitude,
      cidade: p.cidade,
      estado: p.estado,
      tipo: p.tipo,
      fotoCapa: p.fotoCapa,
      fotos: p.fotos,
      tags: p.tags,
      avgNota: p.avgNota,
      totalAvaliacoes: p.totalAvaliacoes,
      distanciaKm: distanciaKm,
      criadoPor: p.criadoPor,
      criadoEm: p.criadoEm,
    );
  }

  double _grausParaRadianos(double graus) => graus * (pi / 180);
}
