import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pesque_fale_app/features/assistente/data/assistente_api_client.dart';
import 'package:pesque_fale_app/features/assistente/data/assistente_exceptions.dart';
import 'package:pesque_fale_app/features/assistente/data/assistente_repository_http.dart';
import 'package:pesque_fale_app/features/assistente/domain/mensagem_assistente.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => 'token-fake';
}

const _baseUrl = 'http://test.local/v1';

AssistenteRepositoryHttp _repositorio(http.Client client) =>
    AssistenteRepositoryHttp(
      apiClient: AssistenteApiClient(
        baseUrl: _baseUrl,
        tokenStorage: _FakeTokenStorage(),
        client: client,
      ),
    );

http.Response _json(Object corpo, int status) => http.Response(
  jsonEncode(corpo),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('envia a pergunta e o histórico e converte a resposta', () async {
    late http.Request enviada;
    final client = MockClient((request) async {
      enviada = request;
      return _json({
        'data': {
          'resposta': 'Toque no botão abaixo.',
          'acoes': [
            {'tipo': 'abrir_tela', 'tela': 'nova_publicacao', 'rotulo': 'Publicar'},
          ],
        },
      }, 200);
    });

    final resposta = await _repositorio(client).perguntar(
      mensagem: 'Como publico?',
      historico: const [MensagemAssistente.usuario('Oi')],
    );

    expect(enviada.method, 'POST');
    expect(enviada.url.toString(), '$_baseUrl/assistente');
    expect(enviada.headers['Authorization'], 'Bearer token-fake');
    expect(jsonDecode(enviada.body), {
      'mensagem': 'Como publico?',
      'historico': [
        {'papel': 'usuario', 'texto': 'Oi'},
      ],
    });
    expect(resposta.resposta, 'Toque no botão abaixo.');
    expect(resposta.acoes.single.tela, 'nova_publicacao');
  });

  final erros = <int, Type>{
    400: PerguntaInvalidaException,
    401: NaoAutenticadoException,
    429: LimiteAssistenteException,
    503: AssistenteIndisponivelException,
    500: InternalServerException,
  };

  erros.forEach((status, tipo) {
    test('status $status vira $tipo', () async {
      final client = MockClient(
        (_) async => _json({'error': 'X', 'message': 'x'}, status),
      );

      await expectLater(
        _repositorio(client).perguntar(mensagem: 'Oi', historico: const []),
        throwsA(isA<AssistenteException>().having(
          (e) => e.runtimeType,
          'tipo',
          tipo,
        )),
      );
    });
  });

  test('falha de rede vira NetworkException', () async {
    final client = MockClient((_) async => throw http.ClientException('fora'));

    await expectLater(
      _repositorio(client).perguntar(mensagem: 'Oi', historico: const []),
      throwsA(isA<NetworkException>()),
    );
  });

  test('resposta sem texto vira erro interno', () async {
    final client = MockClient(
      (_) async => _json({
        'data': {'resposta': '', 'acoes': []},
      }, 200),
    );

    await expectLater(
      _repositorio(client).perguntar(mensagem: 'Oi', historico: const []),
      throwsA(isA<InternalServerException>()),
    );
  });
}