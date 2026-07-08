import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_exceptions.dart';
import 'package:pesque_fale_app/features/pesquisa/data/usuarios_busca_api_client.dart';
import 'package:pesque_fale_app/features/pesquisa/data/usuarios_busca_repository_http.dart';

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => null;
}

const _baseUrl = 'http://test.local/v1';

void main() {
  test('monta URL com o texto de busca', () async {
    late Uri capturedUri;
    final client = MockClient((request) async {
      capturedUri = request.url;
      return http.Response(jsonEncode({'data': []}), 200);
    });

    final repository = UsuariosBuscaRepositoryHttp(
      apiClient: UsuariosBuscaApiClient(
        baseUrl: _baseUrl,
        tokenStorage: _FakeTokenStorage(),
        client: client,
      ),
    );

    await repository.buscar('danilo');

    expect(capturedUri.queryParameters['busca'], 'danilo');
    expect(capturedUri.path, '/v1/usuarios');
  });

  test('nao chama a API quando texto vazio', () async {
    var chamou = false;
    final client = MockClient((request) async {
      chamou = true;
      return http.Response(jsonEncode({'data': []}), 200);
    });

    final repository = UsuariosBuscaRepositoryHttp(
      apiClient: UsuariosBuscaApiClient(
        baseUrl: _baseUrl,
        tokenStorage: _FakeTokenStorage(),
        client: client,
      ),
    );

    final resultado = await repository.buscar('   ');

    expect(chamou, isFalse);
    expect(resultado, isEmpty);
  });

  test('faz parsing da resposta em lista de UsuarioResumo', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 'u1',
              'nome': 'Danilo',
              'username': 'danilo_pesq',
              'fotoPerfil': null,
              'bio': 'bio',
            },
          ],
        }),
        200,
      );
    });

    final repository = UsuariosBuscaRepositoryHttp(
      apiClient: UsuariosBuscaApiClient(
        baseUrl: _baseUrl,
        tokenStorage: _FakeTokenStorage(),
        client: client,
      ),
    );

    final resultado = await repository.buscar('danilo');

    expect(resultado, hasLength(1));
    expect(resultado.first.username, 'danilo_pesq');
  });

  test('lanca InternalServerException quando status de erro', () async {
    final client = MockClient((request) async {
      return http.Response(jsonEncode({'error': 'INTERNAL_ERROR'}), 500);
    });

    final repository = UsuariosBuscaRepositoryHttp(
      apiClient: UsuariosBuscaApiClient(
        baseUrl: _baseUrl,
        tokenStorage: _FakeTokenStorage(),
        client: client,
      ),
    );

    expect(
      () => repository.buscar('danilo'),
      throwsA(isA<InternalServerException>()),
    );
  });
}
