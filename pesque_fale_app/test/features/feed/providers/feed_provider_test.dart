import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/core/data/paged_result.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/feed/data/curtidas_repository.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_exceptions.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/aba_feed.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_exceptions.dart'
    hide InternalServerException;
import 'package:pesque_fale_app/features/pesquisa/data/pontos_repository.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/filtros_locais.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/ponto.dart';

import '../../chat/support/fake_realtime_manager.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async => throw UnimplementedError();

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async {
    return const AuthResult(
      accessToken: 'token',
      usuario: Usuario(
        id: 'u1',
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
  _FakePublicacoesRepository({
    required this.todas,
    this.seguindoIds = const [],
  });

  final List<Publicacao> todas;
  final List<String> seguindoIds;
  int chamadas = 0;
  bool falhar = false;

  /// Quando definido, o [listar] só responde depois que ele completar —
  /// deixa o teste agir com a requisição em voo.
  Completer<void>? segurar;

  @override
  Future<PagedResult<Publicacao>> listar({
    int pagina = 1,
    int porPagina = 20,
    bool seguindo = false,
  }) async {
    chamadas++;
    await segurar?.future;
    if (falhar) throw const InternalServerException();

    final origem = seguindo
        ? todas.where((p) => seguindoIds.contains(p.id)).toList()
        : todas;

    final inicio = (pagina - 1) * porPagina;
    if (inicio >= origem.length) {
      return PagedResult(
        items: const [],
        total: origem.length,
        pagina: pagina,
        porPagina: porPagina,
      );
    }
    final fim = (inicio + porPagina).clamp(0, origem.length);
    return PagedResult(
      items: origem.sublist(inicio, fim),
      total: origem.length,
      pagina: pagina,
      porPagina: porPagina,
    );
  }

  @override
  Future<Publicacao> buscarPorId(String id) async =>
      todas.firstWhere((p) => p.id == id);

  @override
  Future<void> deletar(String id) async => todas.removeWhere((p) => p.id == id);

  @override
  Future<Publicacao> criar({
    String? descricao,
    String? imagemUrl,
    String? localTexto,
    double? avaliacaoNota,
    String? pontoId,
    List<String> tags = const [],
  }) async => throw UnimplementedError();
}

class _FakeCurtidasRepository implements CurtidasRepository {
  bool falhar = false;
  final List<String> curtidas = [];
  final List<String> descurtidas = [];

  @override
  Future<void> curtir(String publicacaoId) async {
    if (falhar) throw const InternalServerException();
    curtidas.add(publicacaoId);
  }

  @override
  Future<void> descurtir(String publicacaoId) async {
    if (falhar) throw const InternalServerException();
    descurtidas.add(publicacaoId);
  }
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
  Future<Ponto> buscarPorId(String id) async =>
      throw const PontoNaoEncontradoException();
}

Publicacao _publicacao(
  String id, {
  bool jaCurtiu = false,
  int curtidasCount = 0,
  int comentariosCount = 0,
}) {
  return Publicacao(
    id: id,
    autorId: 'autor-$id',
    autorNome: 'Autor $id',
    jaCurtiu: jaCurtiu,
    curtidasCount: curtidasCount,
    comentariosCount: comentariosCount,
    criadoEm: DateTime(2026, 1, 1),
    atualizadoEm: DateTime(2026, 1, 1),
  );
}

FeedProvider _criarProvider({
  required _FakePublicacoesRepository publicacoesRepo,
  _FakeCurtidasRepository? curtidasRepo,
  AuthProvider? authProvider,
  FakeRealtimeManager? realtime,
}) {
  return FeedProvider(
    publicacoesRepo: publicacoesRepo,
    curtidasRepo: curtidasRepo ?? _FakeCurtidasRepository(),
    eventosRepo: _FakeEventosRepository(),
    pontosRepo: _FakePontosRepository(),
    authProvider:
        authProvider ?? AuthProvider(repository: _FakeAuthRepository()),
    realtime: realtime ?? FakeRealtimeManager(),
  );
}

Map<String, dynamic> _novaPublicacao(String id, {String autorId = 'autor-x'}) {
  return {
    'publicacaoId': id,
    'autorId': autorId,
    'timestamp': '2026-10-27T12:00:00.000Z',
  };
}

void main() {
  group('FeedProvider - trocarAba', () {
    test('altera abaAtiva e carrega dados só na primeira vez', () async {
      final publicacoesRepo = _FakePublicacoesRepository(
        todas: [_publicacao('p1')],
      );
      final provider = _criarProvider(publicacoesRepo: publicacoesRepo);

      await provider.trocarAba(AbaFeed.paraVoce);
      expect(provider.abaAtiva, AbaFeed.paraVoce);
      expect(publicacoesRepo.chamadas, 1);
      expect(provider.estadoDe(AbaFeed.paraVoce).status, StatusAba.sucesso);

      await provider.trocarAba(AbaFeed.eventos);
      expect(provider.abaAtiva, AbaFeed.eventos);

      await provider.trocarAba(AbaFeed.paraVoce);
      expect(
        publicacoesRepo.chamadas,
        1,
        reason: 'não deve recarregar ao voltar pra aba já carregada',
      );
    });

    test(
      'aba seguindo sem login fica vazia sem chamar o repositório',
      () async {
        final publicacoesRepo = _FakePublicacoesRepository(todas: []);
        final provider = _criarProvider(publicacoesRepo: publicacoesRepo);

        await provider.trocarAba(AbaFeed.seguindo);

        expect(provider.estadoDe(AbaFeed.seguindo).status, StatusAba.vazio);
        expect(publicacoesRepo.chamadas, 0);
      },
    );
  });

  group('FeedProvider - curtirOuDescurtir', () {
    test('atualiza otimisticamente e mantém após sucesso', () async {
      final p1 = _publicacao('p1', jaCurtiu: false, curtidasCount: 3);
      final publicacoesRepo = _FakePublicacoesRepository(todas: [p1]);
      final curtidasRepo = _FakeCurtidasRepository();
      final authProvider = AuthProvider(repository: _FakeAuthRepository());
      await authProvider.login(email: 'ana@teste.com', senha: '123456');

      final provider = _criarProvider(
        publicacoesRepo: publicacoesRepo,
        curtidasRepo: curtidasRepo,
        authProvider: authProvider,
      );
      await provider.trocarAba(AbaFeed.paraVoce);

      await provider.curtirOuDescurtir(provider.paraVoce.first);

      expect(provider.paraVoce.first.jaCurtiu, isTrue);
      expect(provider.paraVoce.first.curtidasCount, 4);
      expect(curtidasRepo.curtidas, ['p1']);
    });

    test('reverte a atualização otimista quando o repositório falha', () async {
      final p1 = _publicacao('p1', jaCurtiu: false, curtidasCount: 3);
      final publicacoesRepo = _FakePublicacoesRepository(todas: [p1]);
      final curtidasRepo = _FakeCurtidasRepository()..falhar = true;
      final authProvider = AuthProvider(repository: _FakeAuthRepository());
      await authProvider.login(email: 'ana@teste.com', senha: '123456');

      final provider = _criarProvider(
        publicacoesRepo: publicacoesRepo,
        curtidasRepo: curtidasRepo,
        authProvider: authProvider,
      );
      await provider.trocarAba(AbaFeed.paraVoce);

      await expectLater(
        provider.curtirOuDescurtir(provider.paraVoce.first),
        throwsA(isA<InternalServerException>()),
      );

      expect(provider.paraVoce.first.jaCurtiu, isFalse);
      expect(provider.paraVoce.first.curtidasCount, 3);
    });

    test(
      'publicação presente em Para você e Seguindo é atualizada nas duas',
      () async {
        final p1 = _publicacao('p1', jaCurtiu: false, curtidasCount: 1);
        final publicacoesRepo = _FakePublicacoesRepository(
          todas: [p1],
          seguindoIds: ['p1'],
        );
        final authProvider = AuthProvider(repository: _FakeAuthRepository());
        await authProvider.login(email: 'ana@teste.com', senha: '123456');

        final provider = _criarProvider(
          publicacoesRepo: publicacoesRepo,
          authProvider: authProvider,
        );
        await provider.trocarAba(AbaFeed.paraVoce);
        await provider.trocarAba(AbaFeed.seguindo);

        await provider.curtirOuDescurtir(provider.paraVoce.first);

        expect(
          provider.paraVoce.firstWhere((p) => p.id == 'p1').jaCurtiu,
          isTrue,
        );
        expect(
          provider.seguindo.firstWhere((p) => p.id == 'p1').jaCurtiu,
          isTrue,
        );
      },
    );
  });

  group('FeedProvider - paginação', () {
    List<Publicacao> gerarPublicacoes(int quantidade) =>
        List.generate(quantidade, (i) => _publicacao('p$i'));

    test('carregarMais incrementa a página e concatena os itens', () async {
      final publicacoesRepo = _FakePublicacoesRepository(
        todas: gerarPublicacoes(25),
      );
      final provider = _criarProvider(publicacoesRepo: publicacoesRepo);

      await provider.trocarAba(AbaFeed.paraVoce);
      expect(provider.paraVoce, hasLength(20));
      expect(publicacoesRepo.chamadas, 1);

      await provider.carregarMais();

      expect(provider.paraVoce, hasLength(25));
      expect(publicacoesRepo.chamadas, 2);
      expect(provider.estadoDe(AbaFeed.paraVoce).status, StatusAba.sucesso);
    });

    test('carregarMais não faz nada quando não há mais páginas', () async {
      final publicacoesRepo = _FakePublicacoesRepository(
        todas: gerarPublicacoes(5),
      );
      final provider = _criarProvider(publicacoesRepo: publicacoesRepo);

      await provider.trocarAba(AbaFeed.paraVoce);
      expect(publicacoesRepo.chamadas, 1);

      await provider.carregarMais();

      expect(
        publicacoesRepo.chamadas,
        1,
        reason: 'não deve chamar o repositório de novo',
      );
      expect(provider.paraVoce, hasLength(5));
    });

    test('pullRefresh reseta a paginação para a primeira página', () async {
      final publicacoesRepo = _FakePublicacoesRepository(
        todas: gerarPublicacoes(25),
      );
      final provider = _criarProvider(publicacoesRepo: publicacoesRepo);

      await provider.trocarAba(AbaFeed.paraVoce);
      await provider.carregarMais();
      expect(provider.paraVoce, hasLength(25));

      await provider.pullRefresh();

      expect(provider.paraVoce, hasLength(20));
      expect(publicacoesRepo.chamadas, 3);
    });
  });

  group('FeedProvider - comentários e remoção', () {
    test('atualizarContadorComentarios aplica o delta na publicação', () async {
      final p1 = _publicacao('p1', comentariosCount: 2);
      final publicacoesRepo = _FakePublicacoesRepository(todas: [p1]);
      final provider = _criarProvider(publicacoesRepo: publicacoesRepo);
      await provider.trocarAba(AbaFeed.paraVoce);

      provider.atualizarContadorComentarios('p1', 1);
      expect(provider.paraVoce.first.comentariosCount, 3);

      provider.atualizarContadorComentarios('p1', -1);
      expect(provider.paraVoce.first.comentariosCount, 2);
    });

    test('removerPublicacao remove das listas Para você e Seguindo', () async {
      final p1 = _publicacao('p1');
      final publicacoesRepo = _FakePublicacoesRepository(
        todas: [p1],
        seguindoIds: ['p1'],
      );
      final authProvider = AuthProvider(repository: _FakeAuthRepository());
      await authProvider.login(email: 'ana@teste.com', senha: '123456');

      final provider = _criarProvider(
        publicacoesRepo: publicacoesRepo,
        authProvider: authProvider,
      );
      await provider.trocarAba(AbaFeed.paraVoce);
      await provider.trocarAba(AbaFeed.seguindo);

      provider.removerPublicacao('p1');

      expect(provider.paraVoce.any((p) => p.id == 'p1'), isFalse);
      expect(provider.seguindo.any((p) => p.id == 'p1'), isFalse);
    });
  });

  group('FeedProvider - nova_publicacao_feed', () {
    late List<Publicacao> todas;
    late List<String> seguindoIds;
    late _FakePublicacoesRepository publicacoesRepo;
    late AuthProvider authProvider;
    late FakeRealtimeManager realtime;
    late FeedProvider provider;

    /// Simula o autor publicando no servidor: a publicação entra no topo
    /// do feed Seguindo que o repositório devolve.
    void publicarNoServidor(String id) {
      todas.insert(0, _publicacao(id));
      seguindoIds.add(id);
    }

    setUp(() async {
      todas = [_publicacao('p1'), _publicacao('p2')];
      seguindoIds = ['p1', 'p2'];
      publicacoesRepo = _FakePublicacoesRepository(
        todas: todas,
        seguindoIds: seguindoIds,
      );
      authProvider = AuthProvider(repository: _FakeAuthRepository());
      await authProvider.login(email: 'ana@teste.com', senha: '123456');
      realtime = FakeRealtimeManager();
      provider = _criarProvider(
        publicacoesRepo: publicacoesRepo,
        authProvider: authProvider,
        realtime: realtime,
      );
      await provider.trocarAba(AbaFeed.seguindo);
    });

    test('evento de outro autor entra nos pendentes e notifica', () {
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      realtime.emitir('nova_publicacao_feed', _novaPublicacao('p3'));

      expect(provider.pendentesSeguindoCount, 1);
      expect(notificacoes, 1);
    });

    test('evento do próprio usuário é no-op', () {
      realtime.emitir(
        'nova_publicacao_feed',
        _novaPublicacao('p3', autorId: 'u1'),
      );

      expect(provider.pendentesSeguindoCount, 0);
    });

    test('publicação já na lista ou repetida não conta de novo', () {
      realtime.emitir('nova_publicacao_feed', _novaPublicacao('p1'));
      expect(provider.pendentesSeguindoCount, 0);

      realtime.emitir('nova_publicacao_feed', _novaPublicacao('p3'));
      realtime.emitir('nova_publicacao_feed', _novaPublicacao('p3'));
      expect(provider.pendentesSeguindoCount, 1);
    });

    test('payload malformado é ignorado', () {
      realtime.emitir('nova_publicacao_feed', 'lixo');
      realtime.emitir('nova_publicacao_feed', {'publicacaoId': 3});

      expect(provider.pendentesSeguindoCount, 0);
    });

    test(
      'aplicarPendentesSeguindo busca a página 1 e faz prepend sem duplicar',
      () async {
        publicarNoServidor('p3');
        publicarNoServidor('p4');
        realtime.emitir('nova_publicacao_feed', _novaPublicacao('p3'));
        realtime.emitir('nova_publicacao_feed', _novaPublicacao('p4'));
        final chamadasAntes = publicacoesRepo.chamadas;

        await provider.aplicarPendentesSeguindo();

        expect(publicacoesRepo.chamadas, chamadasAntes + 1);
        expect(provider.seguindo.map((p) => p.id), ['p4', 'p3', 'p1', 'p2']);
        expect(provider.estadoDe(AbaFeed.seguindo).status, StatusAba.sucesso);
      },
    );

    test('aplicarPendentesSeguindo zera os pendentes', () async {
      publicarNoServidor('p3');
      realtime.emitir('nova_publicacao_feed', _novaPublicacao('p3'));

      await provider.aplicarPendentesSeguindo();

      expect(provider.pendentesSeguindoCount, 0);
    });

    test(
      'aplicarPendentesSeguindo sem pendentes não chama o repositório',
      () async {
        final chamadasAntes = publicacoesRepo.chamadas;

        await provider.aplicarPendentesSeguindo();

        expect(publicacoesRepo.chamadas, chamadasAntes);
      },
    );

    test('aplicarPendentesSeguindo descarta a resposta após logout', () async {
      publicarNoServidor('p3');
      realtime.emitir('nova_publicacao_feed', _novaPublicacao('p3'));

      publicacoesRepo.segurar = Completer<void>();
      final aplicando = provider.aplicarPendentesSeguindo();
      await authProvider.signOut();
      provider.reagirAuth(authProvider);
      publicacoesRepo.segurar!.complete();
      await aplicando;

      expect(provider.seguindo, isEmpty);
    });

    test(
      'carregarMais não duplica o que o prepend empurrou de página',
      () async {
        todas
          ..clear()
          ..addAll(List.generate(25, (i) => _publicacao('s$i')));
        seguindoIds
          ..clear()
          ..addAll(todas.map((p) => p.id));
        await provider.pullRefresh();
        expect(provider.seguindo, hasLength(20));

        publicarNoServidor('novo');
        realtime.emitir('nova_publicacao_feed', _novaPublicacao('novo'));
        await provider.aplicarPendentesSeguindo();
        await provider.carregarMais();

        final ids = provider.seguindo.map((p) => p.id).toList();
        expect(ids, hasLength(26));
        expect(ids.toSet(), hasLength(26));
      },
    );

    test('pullRefresh zera os pendentes', () async {
      realtime.emitir('nova_publicacao_feed', _novaPublicacao('p3'));

      await provider.pullRefresh();

      expect(provider.pendentesSeguindoCount, 0);
    });

    test('carregamento inicial da aba Seguindo zera os pendentes', () async {
      final outro = _criarProvider(
        publicacoesRepo: publicacoesRepo,
        authProvider: authProvider,
        realtime: realtime,
      );
      realtime.emitir('nova_publicacao_feed', _novaPublicacao('p3'));
      expect(outro.pendentesSeguindoCount, 1);

      await outro.trocarAba(AbaFeed.seguindo);

      expect(outro.pendentesSeguindoCount, 0);
    });

    test('logout zera os pendentes', () async {
      realtime.emitir('nova_publicacao_feed', _novaPublicacao('p3'));

      await authProvider.signOut();
      provider.reagirAuth(authProvider);

      expect(provider.pendentesSeguindoCount, 0);
    });

    test('reconexão zera os pendentes', () {
      realtime.emitir('nova_publicacao_feed', _novaPublicacao('p3'));

      realtime.simularReconexao();

      expect(provider.pendentesSeguindoCount, 0);
    });

    test('dispose desfaz as assinaturas no RealtimeManager', () {
      provider.dispose();

      expect(realtime.assinantes['nova_publicacao_feed'], isEmpty);
      expect(realtime.callbacksReconexao, isEmpty);
    });
  });
}
