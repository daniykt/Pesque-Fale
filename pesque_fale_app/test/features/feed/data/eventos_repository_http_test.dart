import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_api_client.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_exceptions.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_repository_http.dart';
import 'package:pesque_fale_app/features/feed/domain/dados_evento.dart';

class _FakeTokenStorage extends TokenStorage {
  _FakeTokenStorage(this.token);

  final String? token;

  @override
  Future<String?> readToken() async => token;
}

const _baseUrl = 'http://test.local/v1';

Map<String, dynamic> _eventoJson({String id = 'ev-1'}) => {
  'id': id,
  'titulo': 'Torneio de Matão',
  'descricao': 'Pesca esportiva',
  'pontoId': null,
  'organizadorId': 'user-1',
  'organizadorNome': 'Ana',
  'dataInicio': '2026-11-20T11:00:00.000Z',
  'dataFim': '2026-11-20T15:00:00.000Z',
  'imagemUrl': null,
  'localTexto': 'Lago Azul',
  'criadoEm': '2026-11-01T12:00:00.000Z',
};

final _dados = DadosEvento(
  titulo: 'Torneio de Matão',
  descricao: 'Pesca esportiva',
  dataInicio: DateTime.utc(2026, 11, 20, 11),
  dataFim: DateTime.utc(2026, 11, 20, 15),
  localTexto: 'Lago Azul',
);

void main() {
  late List<http.Request> requisicoes;

  EventosRepositoryHttp repositorio(
    http.Response Function(http.Request) responder, {
    String? token = 'token-fake',
  }) {
    requisicoes = [];
    return EventosRepositoryHttp(
      apiClient: EventosApiClient(
        baseUrl: _baseUrl,
        tokenStorage: _FakeTokenStorage(token),
        client: MockClient((request) async {
          requisicoes.add(request);
          return responder(request);
        }),
      ),
    );
  }

  http.Response json(Object corpo, int status) => http.Response(
    jsonEncode(corpo),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  group('chamadas', () {
    test('listar pede os futuros com porPagina', () async {
      final repo = repositorio(
        (_) => json({
          'data': [_eventoJson()],
          'meta': {'total': 1},
        }, 200),
      );

      final eventos = await repo.listar(futuros: true, limite: 5);

      expect(eventos.single.id, 'ev-1');
      final uri = requisicoes.single.url;
      expect(requisicoes.single.method, 'GET');
      expect(uri.path, '/v1/eventos');
      expect(uri.queryParameters, {'futuros': 'true', 'porPagina': '5'});
    });

    test('buscarPorId faz GET no id', () async {
      final repo = repositorio((_) => json({'data': _eventoJson()}, 200));

      final evento = await repo.buscarPorId('ev-1');

      expect(evento.titulo, 'Torneio de Matão');
      expect(requisicoes.single.method, 'GET');
      expect(requisicoes.single.url.path, '/v1/eventos/ev-1');
    });

    test('criar faz POST com token e as datas em UTC', () async {
      final repo = repositorio((_) => json({'data': _eventoJson()}, 201));

      final evento = await repo.criar(
        DadosEvento(
          titulo: 'Torneio de Matão',
          dataInicio: DateTime.utc(2026, 11, 20, 11).toLocal(),
        ),
      );

      expect(evento.id, 'ev-1');
      final req = requisicoes.single;
      expect(req.method, 'POST');
      expect(req.url.path, '/v1/eventos');
      expect(req.headers['Authorization'], 'Bearer token-fake');
      expect(jsonDecode(req.body), {
        'titulo': 'Torneio de Matão',
        'descricao': null,
        'dataInicio': '2026-11-20T11:00:00.000Z',
        'dataFim': null,
        'localTexto': null,
        'pontoId': null,
        'imagemUrl': null,
      });
    });

    test('editar faz PATCH no id com todos os campos', () async {
      final repo = repositorio((_) => json({'data': _eventoJson()}, 200));

      await repo.editar('ev-1', _dados);

      final req = requisicoes.single;
      expect(req.method, 'PATCH');
      expect(req.url.path, '/v1/eventos/ev-1');
      expect(req.headers['Authorization'], 'Bearer token-fake');
      final corpo = jsonDecode(req.body) as Map<String, dynamic>;
      expect(corpo['dataInicio'], '2026-11-20T11:00:00.000Z');
      expect(corpo['dataFim'], '2026-11-20T15:00:00.000Z');
      expect(corpo['localTexto'], 'Lago Azul');
      expect(corpo.containsKey('imagemUrl'), isTrue);
    });

    test('excluir faz DELETE no id e aceita 204 sem corpo', () async {
      final repo = repositorio((_) => http.Response('', 204));

      await repo.excluir('ev-1');

      expect(requisicoes.single.method, 'DELETE');
      expect(requisicoes.single.url.path, '/v1/eventos/ev-1');
      expect(requisicoes.single.headers['Authorization'], 'Bearer token-fake');
    });

    test('sem token, não manda Authorization', () async {
      final repo = repositorio(
        (_) => json({'data': <Object>[]}, 200),
        token: null,
      );

      await repo.listar();

      expect(requisicoes.single.headers.containsKey('Authorization'), isFalse);
    });

    test('id com caracteres especiais vai codificado na URL', () async {
      final repo = repositorio((_) => json({'data': _eventoJson()}, 200));

      await repo.buscarPorId('a/b');

      expect(requisicoes.single.url.path, '/v1/eventos/a%2Fb');
    });
  });

  group('datas', () {
    test('lê as datas da API e converte para o horário local', () async {
      final repo = repositorio((_) => json({'data': _eventoJson()}, 200));

      final evento = await repo.buscarPorId('ev-1');

      expect(evento.dataInicio.isUtc, isFalse);
      expect(
        evento.dataInicio.isAtSameMomentAs(DateTime.utc(2026, 11, 20, 11)),
        isTrue,
      );
      expect(evento.dataFim!.isUtc, isFalse);
      expect(
        evento.dataFim!.isAtSameMomentAs(DateTime.utc(2026, 11, 20, 15)),
        isTrue,
      );
      expect(evento.criadoEm.isUtc, isFalse);
    });
  });

  group('erros', () {
    test('404 vira EventoNaoEncontradoException', () async {
      final repo = repositorio(
        (_) => json({
          'error': 'EVENTO_NAO_ENCONTRADO',
          'message': 'Evento não encontrado.',
        }, 404),
      );

      expect(
        () => repo.buscarPorId('x'),
        throwsA(isA<EventoNaoEncontradoException>()),
      );
    });

    test('403 vira EventoSemPermissaoException', () async {
      final repo = repositorio(
        (_) => json({'error': 'FORBIDDEN', 'message': 'Sem permissão'}, 403),
      );

      expect(
        () => repo.excluir('ev-1'),
        throwsA(isA<EventoSemPermissaoException>()),
      );
    });

    test('401 vira EventoNaoAutenticadoException', () async {
      final repo = repositorio(
        (_) => json({'error': 'UNAUTHORIZED', 'message': 'Token'}, 401),
      );

      expect(
        () => repo.criar(_dados),
        throwsA(isA<EventoNaoAutenticadoException>()),
      );
    });

    test('400 traz as mensagens da API por campo', () async {
      final repo = repositorio(
        (_) => json({
          'error': 'VALIDATION_ERROR',
          'message': 'Verifique os campos.',
          'details': [
            {
              'campo': 'titulo',
              'mensagem': 'Título deve ter entre 2 e 200 caracteres.',
            },
            {
              'campo': 'dataFim',
              'mensagem':
                  'A data de fim deve ser igual ou posterior à data de início.',
            },
          ],
        }, 400),
      );

      final erro = await repo
          .criar(_dados)
          .then<Object?>((_) => null, onError: (Object e) => e);

      expect(erro, isA<EventoValidacaoException>());
      final validacao = erro as EventoValidacaoException;
      expect(validacao.errosPorCampo, {
        'titulo': 'Título deve ter entre 2 e 200 caracteres.',
        'dataFim':
            'A data de fim deve ser igual ou posterior à data de início.',
      });
      expect(validacao.message, 'Título deve ter entre 2 e 200 caracteres.');
    });

    test('400 sem details tem mensagem genérica', () async {
      final repo = repositorio(
        (_) => json({
          'error': 'VALIDATION_ERROR',
          'message': 'Nenhum campo para atualizar.',
        }, 400),
      );

      expect(
        () => repo.editar('ev-1', _dados),
        throwsA(
          isA<EventoValidacaoException>()
              .having((e) => e.errosPorCampo, 'errosPorCampo', isEmpty)
              .having(
                (e) => e.message,
                'message',
                'Verifique os campos e tente novamente.',
              ),
        ),
      );
    });

    test('500 e corpo inválido viram EventosServidorException', () async {
      final quebrado = repositorio((_) => http.Response('<html>', 500));
      expect(() => quebrado.listar(), throwsA(isA<EventosServidorException>()));

      final semData = repositorio((_) => json({'ok': true}, 201));
      expect(
        () => semData.criar(_dados),
        throwsA(isA<EventosServidorException>()),
      );
    });

    test('falha de rede vira EventosRedeException', () async {
      final repo = repositorio((_) => throw http.ClientException('sem rede'));

      expect(() => repo.listar(), throwsA(isA<EventosRedeException>()));
    });

    test('mensagens em pt-BR para a tela', () {
      expect(
        const EventoSemPermissaoException().toString(),
        'Só quem organizou o evento pode alterá-lo.',
      );
      expect(
        const EventoNaoAutenticadoException().toString(),
        'Entre na sua conta para criar ou alterar eventos.',
      );
      expect(
        const EventosRedeException().toString(),
        'Sem conexão com o servidor.',
      );
    });
  });
}
