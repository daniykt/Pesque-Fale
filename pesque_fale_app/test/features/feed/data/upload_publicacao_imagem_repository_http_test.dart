import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/feed/data/upload_publicacao_imagem_api_client.dart';
import 'package:pesque_fale_app/features/feed/data/upload_publicacao_imagem_repository_http.dart';

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => 'token-fake';
}

const _baseUrl = 'http://test.local/v1';

UploadPublicacaoImagemRepositoryHttp _buildRepository(http.Client client) {
  return UploadPublicacaoImagemRepositoryHttp(
    apiClient: UploadPublicacaoImagemApiClient(
      baseUrl: _baseUrl,
      tokenStorage: _FakeTokenStorage(),
      client: client,
    ),
  );
}

Future<File> _criarArquivoTemporario() async {
  final dir = await Directory.systemTemp.createTemp('upload_imagem_test_');
  final arquivo = File('${dir.path}/imagem.jpg');
  await arquivo.writeAsBytes(List.filled(10, 0));
  return arquivo;
}

void main() {
  test(
    'retorna imagemUrl quando resposta contem data.imagemUrl',
    () async {
      final arquivo = await _criarArquivoTemporario();
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': {
              'imagemUrl':
                  'https://res.cloudinary.com/xxx/publicacoes/abc.jpg',
            },
          }),
          200,
        );
      });

      final repository = _buildRepository(client);
      final url = await repository.upload(arquivo);

      expect(url, 'https://res.cloudinary.com/xxx/publicacoes/abc.jpg');
    },
  );

  test('lanca excecao quando resposta nao contem imagemUrl', () async {
    final arquivo = await _criarArquivoTemporario();
    final client = MockClient((request) async {
      return http.Response(jsonEncode({'data': <String, dynamic>{}}), 200);
    });

    final repository = _buildRepository(client);

    expect(
      () => repository.upload(arquivo),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('URL não retornada pelo servidor'),
        ),
      ),
    );
  });

  test('lanca excecao quando data e nulo', () async {
    final arquivo = await _criarArquivoTemporario();
    final client = MockClient((request) async {
      return http.Response(jsonEncode(<String, dynamic>{}), 200);
    });

    final repository = _buildRepository(client);

    expect(
      () => repository.upload(arquivo),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('URL não retornada pelo servidor'),
        ),
      ),
    );
  });
}
