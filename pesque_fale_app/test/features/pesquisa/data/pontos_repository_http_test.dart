import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_api_client.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_exceptions.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_repository_http.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/avaliacao_min_filtro.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/filtros_locais.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/tipo_ponto.dart';

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => null;
}

const _baseUrl = 'http://test.local/v1';

Map<String, dynamic> _pontoJson(String id) => {
  'id': id,
  'nome': 'Ponto $id',
  'descricao': 'desc',
  'latitude': -21.6,
  'longitude': -48.3,
  'cidade': 'São Carlos',
  'estado': 'SP',
  'tipo': 'rio',
  'fotoCapa': null,
  'fotos': [],
  'tags': [],
  'avgNota': 4.5,
  'totalAvaliacoes': 10,
  'criadoPor': 'u1',
  'criadoEm': null,
};

void main() {
  test('monta URL sem filtros opcionais quando ausentes', () async {
    late Uri capturedUri;
    final client = MockClient((request) async {
      capturedUri = request.url;
      return http.Response(
        jsonEncode({
          'data': [_pontoJson('1')],
        }),
        200,
      );
    });

    final repository = PontosRepositoryHttp(
      apiClient: PontosApiClient(
        baseUrl: _baseUrl,
        tokenStorage: _FakeTokenStorage(),
        client: client,
      ),
    );

    await repository.buscar(filtros: const FiltrosLocais());

    expect(capturedUri.queryParameters.containsKey('busca'), isFalse);
    expect(capturedUri.queryParameters.containsKey('tipo'), isFalse);
    expect(capturedUri.queryParameters.containsKey('avaliacaoMin'), isFalse);
    expect(capturedUri.queryParameters.containsKey('lat'), isFalse);
    expect(capturedUri.queryParameters.containsKey('raio'), isFalse);
  });

  test(
    'inclui busca, tipo e avaliacaoMin quando presentes nos filtros',
    () async {
      late Uri capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(jsonEncode({'data': []}), 200);
      });

      final repository = PontosRepositoryHttp(
        apiClient: PontosApiClient(
          baseUrl: _baseUrl,
          tokenStorage: _FakeTokenStorage(),
          client: client,
        ),
      );

      await repository.buscar(
        filtros: const FiltrosLocais(
          busca: 'rio',
          tipo: TipoPonto.rio,
          avaliacaoMin: AvaliacaoMinFiltro.quatro,
        ),
      );

      expect(capturedUri.queryParameters['busca'], 'rio');
      expect(capturedUri.queryParameters['tipo'], 'rio');
      expect(capturedUri.queryParameters['avaliacaoMin'], '4.0');
    },
  );

  test('so envia raio quando incluirDistancia e true', () async {
    late Uri capturedComRaio;
    late Uri capturedSemRaio;

    final clientSemRaio = MockClient((request) async {
      capturedSemRaio = request.url;
      return http.Response(jsonEncode({'data': []}), 200);
    });
    final repositorySemRaio = PontosRepositoryHttp(
      apiClient: PontosApiClient(
        baseUrl: _baseUrl,
        tokenStorage: _FakeTokenStorage(),
        client: clientSemRaio,
      ),
    );
    await repositorySemRaio.buscar(
      filtros: const FiltrosLocais(raioKm: 30),
      lat: -21.6,
      lng: -48.3,
      incluirDistancia: false,
    );
    expect(capturedSemRaio.queryParameters.containsKey('raio'), isFalse);
    expect(capturedSemRaio.queryParameters['lat'], isNotNull);

    final clientComRaio = MockClient((request) async {
      capturedComRaio = request.url;
      return http.Response(jsonEncode({'data': []}), 200);
    });
    final repositoryComRaio = PontosRepositoryHttp(
      apiClient: PontosApiClient(
        baseUrl: _baseUrl,
        tokenStorage: _FakeTokenStorage(),
        client: clientComRaio,
      ),
    );
    await repositoryComRaio.buscar(
      filtros: const FiltrosLocais(raioKm: 30),
      lat: -21.6,
      lng: -48.3,
      incluirDistancia: true,
    );
    expect(capturedComRaio.queryParameters['raio'], '30.0');
  });

  test('faz parsing da resposta em lista de Ponto', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'data': [_pontoJson('1'), _pontoJson('2')],
        }),
        200,
      );
    });

    final repository = PontosRepositoryHttp(
      apiClient: PontosApiClient(
        baseUrl: _baseUrl,
        tokenStorage: _FakeTokenStorage(),
        client: client,
      ),
    );

    final pontos = await repository.buscar(filtros: const FiltrosLocais());

    expect(pontos, hasLength(2));
    expect(pontos.first.nome, 'Ponto 1');
    expect(pontos.first.tipo, TipoPonto.rio);
  });

  test('lanca InternalServerException quando status de erro', () async {
    final client = MockClient((request) async {
      return http.Response(jsonEncode({'error': 'INTERNAL_ERROR'}), 500);
    });

    final repository = PontosRepositoryHttp(
      apiClient: PontosApiClient(
        baseUrl: _baseUrl,
        tokenStorage: _FakeTokenStorage(),
        client: client,
      ),
    );

    expect(
      () => repository.buscar(filtros: const FiltrosLocais()),
      throwsA(isA<InternalServerException>()),
    );
  });

  test('lanca NetworkException quando o client lanca excecao', () async {
    final client = MockClient((request) async {
      throw http.ClientException('falhou');
    });

    final repository = PontosRepositoryHttp(
      apiClient: PontosApiClient(
        baseUrl: _baseUrl,
        tokenStorage: _FakeTokenStorage(),
        client: client,
      ),
    );

    expect(
      () => repository.buscar(filtros: const FiltrosLocais()),
      throwsA(isA<NetworkException>()),
    );
  });

  group('buscarPorId', () {
    test('monta URL e faz parsing do ponto', () async {
      late Uri capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(jsonEncode({'data': _pontoJson('1')}), 200);
      });

      final repository = PontosRepositoryHttp(
        apiClient: PontosApiClient(
          baseUrl: _baseUrl,
          tokenStorage: _FakeTokenStorage(),
          client: client,
        ),
      );

      final ponto = await repository.buscarPorId('1');

      expect(capturedUri.path, '/v1/pontos/1');
      expect(ponto.id, '1');
    });

    test('lanca PontoNaoEncontradoException quando status 404', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'PONTO_NAO_ENCONTRADO'}),
          404,
        );
      });

      final repository = PontosRepositoryHttp(
        apiClient: PontosApiClient(
          baseUrl: _baseUrl,
          tokenStorage: _FakeTokenStorage(),
          client: client,
        ),
      );

      expect(
        () => repository.buscarPorId('id-inexistente'),
        throwsA(isA<PontoNaoEncontradoException>()),
      );
    });
  });
}
