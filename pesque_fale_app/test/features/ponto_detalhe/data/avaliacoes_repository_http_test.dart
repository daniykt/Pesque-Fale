import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/data/avaliacoes_api_client.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/data/avaliacoes_exceptions.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/data/avaliacoes_repository_http.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/domain/criar_editar_avaliacao_input.dart';

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => 'token-fake';
}

const _baseUrl = 'http://test.local/v1';

Map<String, dynamic> _avaliacaoJson(String id) => {
  'id': id,
  'usuarioId': 'u1',
  'usuarioNome': 'João Vítor',
  'usuarioUsername': 'joaovitor',
  'usuarioFoto': null,
  'pontoId': 'p1',
  'nota': 4.5,
  'comentario': 'Excelente lugar',
  'criadoEm': '2025-06-01T10:00:00.000Z',
  'atualizadoEm': '2025-06-01T10:00:00.000Z',
};

AvaliacoesRepositoryHttp _buildRepository(http.Client client) {
  return AvaliacoesRepositoryHttp(
    apiClient: AvaliacoesApiClient(
      baseUrl: _baseUrl,
      tokenStorage: _FakeTokenStorage(),
      client: client,
    ),
  );
}

void main() {
  test('listar monta a URL com pagina e porPagina e envia Bearer', () async {
    late Uri capturedUri;
    late String? capturedAuth;
    final client = MockClient((request) async {
      capturedUri = request.url;
      capturedAuth = request.headers['Authorization'];
      return http.Response(
        jsonEncode({
          'data': [_avaliacaoJson('a1')],
          'meta': {'total': 1, 'pagina': 1, 'porPagina': 20},
        }),
        200,
      );
    });

    final repository = _buildRepository(client);
    final resultado = await repository.listar('p1', pagina: 2, porPagina: 10);

    expect(capturedUri.path, '/v1/pontos/p1/avaliacoes');
    expect(capturedUri.queryParameters['pagina'], '2');
    expect(capturedUri.queryParameters['porPagina'], '10');
    expect(capturedAuth, 'Bearer token-fake');
    expect(resultado, hasLength(1));
    expect(resultado.first.nota, 4.5);
  });

  test('minhaAvaliacao retorna a avaliacao quando existe', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/pontos/p1/avaliacoes/minha');
      return http.Response(jsonEncode({'data': _avaliacaoJson('a1')}), 200);
    });

    final repository = _buildRepository(client);
    final minha = await repository.minhaAvaliacao('p1');

    expect(minha, isNotNull);
    expect(minha!.id, 'a1');
  });

  test('minhaAvaliacao retorna null quando o backend responde 404', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'error': 'AVALIACAO_NAO_ENCONTRADA',
          'message': 'Você ainda não avaliou este ponto.',
        }),
        404,
      );
    });

    final repository = _buildRepository(client);
    final minha = await repository.minhaAvaliacao('p1');

    expect(minha, isNull);
  });

  test('criar lanca JaAvaliouException quando o backend responde 409', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'error': 'AVALIACAO_JA_EXISTE',
          'message': 'Você já avaliou este ponto.',
        }),
        409,
      );
    });

    final repository = _buildRepository(client);

    expect(
      () => repository.criar(
        'p1',
        const CriarEditarAvaliacaoInput(nota: 4),
      ),
      throwsA(isA<JaAvaliouException>()),
    );
  });

  test(
    'criar lanca NaoAutenticadoException quando o backend responde 401',
    () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'TOKEN_INVALIDO',
            'message': 'Token não fornecido.',
          }),
          401,
        );
      });

      final repository = _buildRepository(client);

      expect(
        () => repository.criar(
          'p1',
          const CriarEditarAvaliacaoInput(nota: 4),
        ),
        throwsA(isA<NaoAutenticadoException>()),
      );
    },
  );

  test('editar envia PATCH para /minha com o corpo correto', () async {
    late Uri capturedUri;
    late Map<String, dynamic> capturedBody;
    final client = MockClient((request) async {
      capturedUri = request.url;
      capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({'data': _avaliacaoJson('a1')}), 200);
    });

    final repository = _buildRepository(client);
    await repository.editar(
      'p1',
      const CriarEditarAvaliacaoInput(nota: 3.5, comentario: 'Atualizado'),
    );

    expect(capturedUri.path, '/v1/pontos/p1/avaliacoes/minha');
    expect(capturedBody['nota'], 3.5);
    expect(capturedBody['comentario'], 'Atualizado');
  });

  test('deletar envia DELETE para /minha', () async {
    late Uri capturedUri;
    late String capturedMethod;
    final client = MockClient((request) async {
      capturedUri = request.url;
      capturedMethod = request.method;
      return http.Response('', 204);
    });

    final repository = _buildRepository(client);
    await repository.deletar('p1');

    expect(capturedUri.path, '/v1/pontos/p1/avaliacoes/minha');
    expect(capturedMethod, 'DELETE');
  });

  test('lanca InternalServerException para erro desconhecido', () async {
    final client = MockClient((request) async {
      return http.Response(jsonEncode({'error': 'INTERNAL_ERROR'}), 500);
    });

    final repository = _buildRepository(client);

    expect(() => repository.listar('p1'), throwsA(isA<InternalServerException>()));
  });
}
