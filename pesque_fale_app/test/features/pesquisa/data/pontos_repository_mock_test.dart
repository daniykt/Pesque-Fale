import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_repository_mock.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/avaliacao_min_filtro.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/filtros_locais.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/tipo_ponto.dart';

void main() {
  late PontosRepositoryMock repository;

  setUp(() {
    repository = PontosRepositoryMock();
  });

  test('retorna lista de pontos quando busca vazia', () async {
    final pontos = await repository.buscar(filtros: const FiltrosLocais());

    expect(pontos, isNotEmpty);
    expect(pontos.length, greaterThanOrEqualTo(10));
  });

  test('aplica filtro de tipo', () async {
    final pontos = await repository.buscar(
      filtros: const FiltrosLocais(tipo: TipoPonto.rio),
    );

    expect(pontos, isNotEmpty);
    expect(pontos.every((p) => p.tipo == TipoPonto.rio), isTrue);
  });

  test('aplica filtro de avaliacao minima', () async {
    final pontos = await repository.buscar(
      filtros: const FiltrosLocais(avaliacaoMin: AvaliacaoMinFiltro.quatro),
    );

    expect(pontos, isNotEmpty);
    expect(pontos.every((p) => p.avgNota >= 4.0), isTrue);
  });

  test('calcula distancia quando lat/lng informados e incluirDistancia', () async {
    final pontos = await repository.buscar(
      filtros: const FiltrosLocais(),
      lat: -21.6082,
      lng: -48.3658,
      incluirDistancia: true,
    );

    expect(pontos, isNotEmpty);
    expect(pontos.every((p) => p.distanciaKm != null), isTrue);
  });

  test('nao calcula distancia quando incluirDistancia e falso', () async {
    final pontos = await repository.buscar(
      filtros: const FiltrosLocais(),
      lat: -21.6082,
      lng: -48.3658,
    );

    expect(pontos.every((p) => p.distanciaKm == null), isTrue);
  });

  test('retorna vazio quando busca nao bate com nenhum ponto', () async {
    final pontos = await repository.buscar(
      filtros: const FiltrosLocais(busca: 'ponto-inexistente-xyz'),
    );

    expect(pontos, isEmpty);
  });
}
