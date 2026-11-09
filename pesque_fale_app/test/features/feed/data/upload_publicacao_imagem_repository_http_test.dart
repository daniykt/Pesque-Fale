import 'dart:convert';
import 'dart:typed_data';

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

Uint8List _bytesFake({int tamanho = 10}) =>
    Uint8List.fromList(List<int>.filled(tamanho, 0));

void main() {
  test(
    'retorna imagemUrl quando resposta contem data.imagemUrl',
    () async {
      final bytes = _bytesFake();
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
      final url = await repository.upload(
        bytes,
        filename: 'foto.jpg',
        mimeType: 'image/jpeg',
      );

      expect(url, 'https://res.cloudinary.com/xxx/publicacoes/abc.jpg');
    },
  );

  test('lanca excecao quando resposta nao contem imagemUrl', () async {
    final bytes = _bytesFake();
    final client = MockClient((request) async {
      return http.Response(jsonEncode({'data': <String, dynamic>{}}), 200);
    });

    final repository = _buildRepository(client);

    expect(
      () => repository.upload(
        bytes,
        filename: 'foto.jpg',
        mimeType: 'image/jpeg',
      ),
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
    final bytes = _bytesFake();
    final client = MockClient((request) async {
      return http.Response(jsonEncode(<String, dynamic>{}), 200);
    });

    final repository = _buildRepository(client);

    expect(
      () => repository.upload(
        bytes,
        filename: 'foto.jpg',
        mimeType: 'image/jpeg',
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('URL não retornada pelo servidor'),
        ),
      ),
    );
  });

  test('envia multipart com filename e bytes preservados', () async {
    final bytes = _bytesFake(tamanho: 7);
    String? filenameEnviado;
    int? tamanhoCorpo;

    final client = MockClient((request) async {
      filenameEnviado = RegExp(
        r'filename="([^"]+)"',
      ).firstMatch(request.body)?.group(1);
      tamanhoCorpo = request.bodyBytes.length;
      return http.Response(
        jsonEncode({
          'data': {'imagemUrl': 'https://res.cloudinary.com/xxx/ok.jpg'},
        }),
        200,
      );
    });

    final repository = _buildRepository(client);
    await repository.upload(
      bytes,
      filename: 'minha-foto.jpg',
      mimeType: 'image/jpeg',
    );

    expect(filenameEnviado, 'minha-foto.jpg');
    expect(tamanhoCorpo, isNotNull);
    expect(tamanhoCorpo! > bytes.length, isTrue);
  });
}
