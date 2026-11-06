import 'package:flutter_test/flutter_test.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:pesque_fale_app/core/data/paged_result.dart';
import 'package:pesque_fale_app/core/realtime/realtime_manager.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/feed/data/curtidas_repository.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/aba_feed.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_repository.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/filtros_locais.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/ponto.dart';

class _FakeSocket extends Fake implements io.Socket {
  final Map<String, List<dynamic Function(dynamic)>> handlers = {};
  bool descartado = false;

  @override
  dynamic Function() on(String event, dynamic Function(dynamic) handler) {
    handlers.putIfAbsent(event, () => []).add(handler);
    return () => off(event, handler);
  }

  @override
  void off(String event, [dynamic Function(dynamic)? handler]) {
    handler == null ? handlers.remove(event) : handlers[event]?.remove(handler);
  }

  @override
  void emit(String event, [dynamic data]) {}

  @override
  io.Socket connect() => this;

  @override
  void dispose() {
    descartado = true;
    handlers.clear();
  }

  void simular(String evento, [dynamic dados]) {
    for (final h in List.of(handlers[evento] ?? const [])) {
      h(dados);
    }
  }

  void quedaEVolta() {
    simular('disconnect');
    simular('connect');
  }
}

class _FakeAuthRepository implements AuthRepository {
  int logins = 0;

  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) => throw UnimplementedError();

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async {
    logins++;
    return AuthResult(
      accessToken: 'token-$logins',
      usuario: const Usuario(
        id: 'eu',
        nome: 'Ana',
        email: 'ana@teste.com',
        onboardingConcluido: true,
      ),
    );
  }

  @override
  Future<void> logout() async {}
}

class _FakePublicacoesRepository implements PublicacoesRepository {
  final List<Publicacao> todas = [
    Publicacao(
      id: 'p1',
      autorId: 'autor-1',
      autorNome: 'Autor',
      curtidasCount: 1,
      criadoEm: DateTime(2026, 1, 1),
      atualizadoEm: DateTime(2026, 1, 1),
    ),
  ];

  @override
  Future<PagedResult<Publicacao>> listar({
    int pagina = 1,
    int porPagina = 20,
    bool seguindo = false,
  }) async => PagedResult(
    items: pagina == 1 ? List.of(todas) : const [],
    total: todas.length,
    pagina: pagina,
    porPagina: porPagina,
  );

  @override
  Future<Publicacao> buscarPorId(String id) => throw UnimplementedError();

  @override
  Future<void> deletar(String id) async {}

  @override
  Future<Publicacao> criar({
    String? descricao,
    String? imagemUrl,
    String? localTexto,
    double? avaliacaoNota,
    String? pontoId,
    List<String> tags = const [],
  }) => throw UnimplementedError();
}

class _FakeCurtidasRepository implements CurtidasRepository {
  @override
  Future<void> curtir(String publicacaoId) async {}

  @override
  Future<void> descurtir(String publicacaoId) async {}
}

class _FakeEventosRepository implements EventosRepository {
  @override
  Future<List<Evento>> listar({bool futuros = true, int limite = 10}) async =>
      const [];
}

class _FakePontosRepository implements PontosRepository {
  @override
  Future<List<Ponto>> buscar({
    required FiltrosLocais filtros,
    double? lat,
    double? lng,
    bool incluirDistancia = false,
    String? ordem,
  }) async => const [];

  @override
  Future<Ponto> buscarPorId(String id) => throw UnimplementedError();
}

class _StoreQueConta extends PublicacoesStore {
  int atualizacoesDeCurtida = 0;

  @override
  void atualizarCurtidasCount(String id, int total) {
    atualizacoesDeCurtida++;
    super.atualizarCurtidasCount(id, total);
  }
}

const _eventosDaHome = [
  'nova_publicacao_feed',
  'publicacao_criada',
  'publicacao_removida',
  'publicacao_curtidas',
  'publicacao_comentarios',
];

void main() {
  late List<_FakeSocket> sockets;
  late RealtimeManager realtime;
  late AuthProvider auth;
  late _StoreQueConta store;
  late FeedProvider feed;

  Future<void> entrar() async {
    await auth.login(email: 'ana@teste.com', senha: '123456');
    realtime.reagirAuth(auth);
    feed.reagirAuth(auth);
    sockets.last.simular('connect');
    await pumpEventQueue();
  }

  Future<void> sair() async {
    await auth.signOut();
    realtime.reagirAuth(auth);
    feed.reagirAuth(auth);
    await pumpEventQueue();
  }

  setUp(() {
    sockets = [];
    realtime = RealtimeManager(
      criarSocket: (_) {
        final s = _FakeSocket();
        sockets.add(s);
        return s;
      },
    );
    auth = AuthProvider(repository: _FakeAuthRepository());
    store = _StoreQueConta();
    feed = FeedProvider(
      publicacoesRepo: _FakePublicacoesRepository(),
      curtidasRepo: _FakeCurtidasRepository(),
      eventosRepo: _FakeEventosRepository(),
      pontosRepo: _FakePontosRepository(),
      authProvider: auth,
      realtime: realtime,
      store: store,
    );
  });

  test(
    'depois de quedas, logout e login, cada evento chega ao FeedProvider uma vez só',
    () async {
      await entrar();
      await feed.trocarAba(AbaFeed.paraVoce);
      sockets.last
        ..quedaEVolta()
        ..quedaEVolta();
      await pumpEventQueue();

      await sair();
      await entrar();
      sockets.last
        ..quedaEVolta()
        ..quedaEVolta()
        ..quedaEVolta();
      await pumpEventQueue();

      expect(sockets, hasLength(2));
      expect(sockets.first.descartado, isTrue);
      for (final evento in _eventosDaHome) {
        expect(sockets.last.handlers[evento], hasLength(1), reason: evento);
      }

      sockets.last.simular('publicacao_curtidas', {
        'publicacaoId': 'p1',
        'curtidasCount': 7,
        'porId': 'outra-pessoa',
      });

      expect(store.atualizacoesDeCurtida, 1);
      expect(store.porId('p1')!.curtidasCount, 7);
    },
  );

  test('o socket da sessão anterior não entrega mais eventos', () async {
    await entrar();
    await feed.trocarAba(AbaFeed.paraVoce);
    final antigo = sockets.last;

    await sair();
    await entrar();
    antigo.simular('publicacao_curtidas', {
      'publicacaoId': 'p1',
      'curtidasCount': 7,
      'porId': 'outra-pessoa',
    });

    expect(store.atualizacoesDeCurtida, 0);
  });

  test('dispose do FeedProvider tira os handlers do socket atual', () async {
    await entrar();

    feed.dispose();

    for (final evento in _eventosDaHome) {
      expect(
        sockets.last.handlers[evento] ?? const [],
        isEmpty,
        reason: evento,
      );
    }
  });
}
