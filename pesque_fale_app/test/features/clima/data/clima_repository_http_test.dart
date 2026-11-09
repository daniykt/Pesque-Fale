import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pesque_fale_app/features/clima/data/clima_api_client.dart';
import 'package:pesque_fale_app/features/clima/data/clima_exceptions.dart';
import 'package:pesque_fale_app/features/clima/data/clima_repository_http.dart';
import 'package:pesque_fale_app/features/clima/domain/condicao_clima.dart';
import 'package:pesque_fale_app/features/clima/domain/data_por_extenso.dart';

Map<String, dynamic> _respostaOpenMeteo({
  Object? temperatura = 24.6,
  Object? umidade = 71,
  Object? vento = 9.4,
  Object? codigo = 3,
}) => {
  'latitude': -21.6,
  'longitude': -48.36,
  'current_units': {'temperature_2m': '°C', 'wind_speed_10m': 'km/h'},
  'current': {
    'time': '2026-11-06T20:00',
    'interval': 900,
    'temperature_2m': temperatura,
    'relative_humidity_2m': umidade,
    'wind_speed_10m': vento,
    'weather_code': codigo,
  },
};

void main() {
  late List<http.Request> requisicoes;

  ClimaRepositoryHttp repositorio(
    Future<http.Response> Function(http.Request) responder,
  ) {
    requisicoes = [];
    return ClimaRepositoryHttp(
      apiClient: ClimaApiClient(
        client: MockClient((req) {
          requisicoes.add(req);
          return responder(req);
        }),
      ),
    );
  }

  test(
    'pede o clima atual ao Open-Meteo com a coordenada arredondada',
    () async {
      final repo = repositorio(
        (_) async => http.Response(jsonEncode(_respostaOpenMeteo()), 200),
      );

      await repo.buscarAtual(latitude: -21.60352, longitude: -48.36521);

      final uri = requisicoes.single.url;
      expect(uri.host, 'api.open-meteo.com');
      expect(uri.path, '/v1/forecast');
      expect(uri.queryParameters['latitude'], '-21.60');
      expect(uri.queryParameters['longitude'], '-48.37');
      expect(uri.toString(), isNot(contains('21.6035')));
      expect(uri.toString(), isNot(contains('48.365')));
      expect(
        uri.queryParameters['current']!.split(','),
        containsAll([
          'temperature_2m',
          'relative_humidity_2m',
          'wind_speed_10m',
          'weather_code',
        ]),
      );
      expect(uri.queryParameters['wind_speed_unit'], 'kmh');
    },
  );

  test('converte a resposta em Clima', () async {
    final repo = repositorio(
      (_) async => http.Response(jsonEncode(_respostaOpenMeteo()), 200),
    );

    final clima = await repo.buscarAtual(latitude: -21.6, longitude: -48.36);

    expect(clima.temperatura, 24.6);
    expect(clima.umidade, 71);
    expect(clima.ventoKmh, 9.4);
    expect(clima.condicao, CondicaoClima.nublado);
  });

  test('erro HTTP vira ClimaServicoException', () async {
    final repo = repositorio((_) async => http.Response('falhou', 500));

    expect(
      repo.buscarAtual(latitude: 0, longitude: 0),
      throwsA(isA<ClimaServicoException>()),
    );
  });

  test('corpo que não é JSON vira ClimaServicoException', () async {
    final repo = repositorio((_) async => http.Response('<html>', 200));

    expect(
      repo.buscarAtual(latitude: 0, longitude: 0),
      throwsA(isA<ClimaServicoException>()),
    );
  });

  test(
    'campos ausentes ou de tipo errado viram ClimaServicoException',
    () async {
      for (final corpo in [
        <String, dynamic>{},
        _respostaOpenMeteo(temperatura: null),
        _respostaOpenMeteo(umidade: '71'),
        _respostaOpenMeteo(codigo: null),
      ]) {
        final repo = repositorio(
          (_) async => http.Response(jsonEncode(corpo), 200),
        );

        await expectLater(
          repo.buscarAtual(latitude: 0, longitude: 0),
          throwsA(isA<ClimaServicoException>()),
          reason: '$corpo',
        );
      }
    },
  );

  test('falha de rede vira ClimaRedeException', () async {
    final repo = repositorio(
      (_) async => throw http.ClientException('sem internet'),
    );

    expect(
      repo.buscarAtual(latitude: 0, longitude: 0),
      throwsA(isA<ClimaRedeException>()),
    );
  });

  group('CondicaoClima.doCodigo', () {
    test('traduz os códigos WMO para pt-BR', () {
      expect(CondicaoClima.doCodigo(0).descricao, 'Céu limpo');
      expect(CondicaoClima.doCodigo(2).descricao, 'Parcialmente nublado');
      expect(CondicaoClima.doCodigo(45).descricao, 'Neblina');
      expect(CondicaoClima.doCodigo(53).descricao, 'Garoa');
      expect(CondicaoClima.doCodigo(63).descricao, 'Chuva');
      expect(CondicaoClima.doCodigo(65).descricao, 'Chuva forte');
      expect(CondicaoClima.doCodigo(81).descricao, 'Pancadas de chuva');
      expect(CondicaoClima.doCodigo(95).descricao, 'Trovoada');
      expect(CondicaoClima.doCodigo(99).descricao, 'Trovoada com granizo');
    });

    test('código desconhecido não inventa condição', () {
      expect(CondicaoClima.doCodigo(42), CondicaoClima.desconhecida);
      expect(CondicaoClima.doCodigo(42).descricao, 'Condição não informada');
    });
  });

  test('dataPorExtenso escreve a data em pt-BR', () {
    expect(dataPorExtenso(DateTime(2026, 11, 6)), 'Sexta-feira, 6 de novembro');
    expect(dataPorExtenso(DateTime(2026, 3, 1)), 'Domingo, 1 de março');
  });
}
