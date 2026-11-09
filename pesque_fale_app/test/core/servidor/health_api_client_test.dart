import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pesque_fale_app/core/servidor/health_api_client.dart';

void main() {
  group('HealthApiClient.uriDoHealth', () {
    test('produção: tira o /v1 e vai para a raiz do servidor', () {
      expect(
        HealthApiClient.uriDoHealth(
          'https://pesque-fale-api.onrender.com/v1',
        ).toString(),
        'https://pesque-fale-api.onrender.com/health',
      );
    });

    test('API local mantém host e porta', () {
      expect(
        HealthApiClient.uriDoHealth('http://10.0.2.2:3333/v1').toString(),
        'http://10.0.2.2:3333/health',
      );
    });
  });

  group('HealthApiClient.checar', () {
    test('faz GET no /health e devolve true com 200', () async {
      late http.Request recebida;
      final api = HealthApiClient(
        apiBaseUrl: 'https://api.teste/v1',
        client: MockClient((request) async {
          recebida = request;
          return http.Response('{"status":"ok"}', 200);
        }),
      );

      expect(await api.checar(timeout: const Duration(seconds: 5)), isTrue);
      expect(recebida.method, 'GET');
      expect(recebida.url.toString(), 'https://api.teste/health');
    });

    test('502 do Render subindo devolve false', () async {
      final api = HealthApiClient(
        apiBaseUrl: 'https://api.teste/v1',
        client: MockClient((_) async => http.Response('', 502)),
      );

      expect(await api.checar(timeout: const Duration(seconds: 5)), isFalse);
    });

    test('erro de rede sobe como exceção', () async {
      final api = HealthApiClient(
        apiBaseUrl: 'https://api.teste/v1',
        client: MockClient((_) async => throw http.ClientException('fora')),
      );

      expect(
        api.checar(timeout: const Duration(seconds: 5)),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
