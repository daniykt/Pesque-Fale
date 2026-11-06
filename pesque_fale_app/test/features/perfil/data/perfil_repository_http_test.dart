import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_api_client.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_exceptions.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository_http.dart';

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => 'token-teste';
}

const _baseUrl = 'http://test.local/v1';
const _perfilPath = '/v1/usuarios/user-2';
const _publicacoesPath = '/v1/usuarios/user-2/publicacoes';

http.Response _json(int status, Map<String, dynamic> body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

final _perfilOk = _json(200, {
  'data': {
    'id': 'user-2',
    'nome': 'Ana Pesca',
    'username': 'ana_pesca',
    'seguidores': 10,
    'seguindo': 4,
    'souSeguidor': true,
    'meSegue': false,
  },
});

final _publicacoesOk = _json(200, {
  'data': [
    {'id': 'pub-1', 'autorId': 'user-2', 'autorNome': 'Ana Pesca'},
    {'id': 'pub-2', 'autorId': 'user-2', 'autorNome': 'Ana Pesca'},
  ],
  'meta': {'total': 30, 'pagina': 1, 'porPagina': 12},
});

final _perfil404 = _json(404, {
  'error': 'USUARIO_NAO_ENCONTRADO',
  'message': 'Usuário não encontrado.',
});

final _publicacoes500 = _json(500, {
  'error': 'INTERNAL_ERROR',
  'message': 'Erro interno no servidor.',
});

/// Servidor falso que segura cada resposta até o teste mandar responder.
/// Permite ver quais requisições já chegaram e escolher a ordem das respostas.
class _ServidorControlado {
  final _respostas = {
    _perfilPath: Completer<http.Response>(),
    _publicacoesPath: Completer<http.Response>(),
  };
  final chegaram = <String>[];

  late final client = MockClient((request) {
    chegaram.add(request.url.path);
    return _respostas[request.url.path]!.future;
  });

  late final repository = PerfilRepositoryHttp(
    apiClient: PerfilApiClient(
      baseUrl: _baseUrl,
      tokenStorage: _FakeTokenStorage(),
      client: client,
    ),
  );

  Future<void> responder(String path, http.Response resposta) async {
    _respostas[path]!.complete(resposta);
    await pumpEventQueue();
  }
}

void main() {
  group('PerfilRepositoryHttp.buscarPerfil', () {
    test(
      'dispara perfil e publicações antes de receber qualquer resposta',
      () async {
        final servidor = _ServidorControlado();

        final resultado = servidor.repository.buscarPerfil(
          'user-2',
          meuId: 'user-1',
        );
        await pumpEventQueue();

        // Nenhuma resposta foi entregue ainda e as duas já chegaram ao servidor.
        expect(
          servidor.chegaram,
          unorderedEquals([_perfilPath, _publicacoesPath]),
        );

        await servidor.responder(_perfilPath, _perfilOk);
        await servidor.responder(_publicacoesPath, _publicacoesOk);
        await resultado;
      },
    );

    test(
      'sucesso monta o PerfilCompleto com usuário, publicações e seguimento',
      () async {
        final servidor = _ServidorControlado();

        final resultado = servidor.repository.buscarPerfil(
          'user-2',
          meuId: 'user-1',
        );
        await pumpEventQueue();
        // Publicações respondem primeiro: a ordem de chegada não importa.
        await servidor.responder(_publicacoesPath, _publicacoesOk);
        await servidor.responder(_perfilPath, _perfilOk);

        final perfil = await resultado;
        expect(perfil.usuario.id, 'user-2');
        expect(perfil.usuario.nome, 'Ana Pesca');
        expect(perfil.usuario.seguidores, 10);
        expect(perfil.publicacoes.map((p) => p.id), ['pub-1', 'pub-2']);
        expect(perfil.isFollowing, isTrue);
        expect(perfil.seguidoPeloOutro, isFalse);
      },
    );

    group(
      'perfil 404 e publicações com erro lança PerfilNaoEncontradoException',
      () {
        test('quando o perfil falha primeiro', () async {
          final servidor = _ServidorControlado();

          final resultado = servidor.repository.buscarPerfil(
            'user-2',
            meuId: 'user-1',
          );
          final expectativa = expectLater(
            resultado,
            throwsA(isA<PerfilNaoEncontradoException>()),
          );
          await pumpEventQueue();
          await servidor.responder(_perfilPath, _perfil404);
          await servidor.responder(_publicacoesPath, _publicacoes500);
          await expectativa;
        });

        test('quando as publicações falham primeiro', () async {
          final servidor = _ServidorControlado();

          final resultado = servidor.repository.buscarPerfil(
            'user-2',
            meuId: 'user-1',
          );
          final expectativa = expectLater(
            resultado,
            throwsA(isA<PerfilNaoEncontradoException>()),
          );
          await pumpEventQueue();
          await servidor.responder(_publicacoesPath, _publicacoes500);
          await servidor.responder(_perfilPath, _perfil404);
          await expectativa;
        });
      },
    );

    group(
      'perfil ok e publicações com erro lança a exceção das publicações',
      () {
        test('quando as publicações falham primeiro', () async {
          final servidor = _ServidorControlado();

          final resultado = servidor.repository.buscarPerfil(
            'user-2',
            meuId: 'user-1',
          );
          final expectativa = expectLater(
            resultado,
            throwsA(isA<InternalServerException>()),
          );
          await pumpEventQueue();
          await servidor.responder(_publicacoesPath, _publicacoes500);
          await servidor.responder(_perfilPath, _perfilOk);
          await expectativa;
        });

        test('quando o perfil responde primeiro', () async {
          final servidor = _ServidorControlado();

          final resultado = servidor.repository.buscarPerfil(
            'user-2',
            meuId: 'user-1',
          );
          final expectativa = expectLater(
            resultado,
            throwsA(isA<InternalServerException>()),
          );
          await pumpEventQueue();
          await servidor.responder(_perfilPath, _perfilOk);
          await servidor.responder(_publicacoesPath, _publicacoes500);
          await expectativa;
        });
      },
    );
  });
}
