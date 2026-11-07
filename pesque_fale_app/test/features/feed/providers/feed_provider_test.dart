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
import 'package:pesque_fale_app/features/feed/domain/dados_evento.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
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

  @override
  Future<Evento> buscarPorId(String id) => throw UnimplementedError();

  @override
  Future<Evento> criar(DadosEvento dados) => throw UnimplementedError();

  @override
  Future<Evento> editar(String id, DadosEvento dados) =>
      throw UnimplementedError();

  @override
  Future<void> excluir(String id) => throw UnimplementedError();
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
  PublicacoesStore? store,
}) {
  return FeedProvider(
    publicacoesRepo: publicacoesRepo,
    curtidasRepo: curtidasRepo ?? _FakeCurtidasRepository(),
    eventosRepo: _FakeEventosRepository(),
    pontosRepo: _FakePontosRepository(),
    authProvider:
        authProvider ?? AuthProvider(repository: _FakeAuthRepository()),
    realtime: realtime ?? FakeRealtimeManager(),
    store: store ?? PublicacoesStore(),
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

    test(
      'Para você não duplica o item empurrado para a página seguinte',
      () async {
        final publicacoesRepo = _FakePublicacoesRepository(
          todas: gerarPublicacoes(25),
        );
        final provider = _criarProvider(publicacoesRepo: publicacoesRepo);
        await provider.trocarAba(AbaFeed.paraVoce);

        publicacoesRepo.todas.insert(0, _publicacao('nova'));
        await provider.carregarMais();

        final ids = provider.paraVoce.map((p) => p.id).toList();
        expect(ids, hasLength(25));
        expect(ids.toSet(), hasLength(ids.length));
        expect(ids.where((id) => id == 'p19'), hasLength(1));
      },
    );

    test('erro no carregarMais mantém a lista e marca a falha', () async {
      final publicacoesRepo = _FakePublicacoesRepository(
        todas: gerarPublicacoes(25),
      );
      final provider = _criarProvider(publicacoesRepo: publicacoesRepo);
      await provider.trocarAba(AbaFeed.paraVoce);

      publicacoesRepo.falhar = true;
      await provider.carregarMais();

      final estado = provider.estadoDe(AbaFeed.paraVoce);
      expect(estado.status, StatusAba.sucesso);
      expect(estado.falhouCarregarMais, isTrue);
      expect(provider.paraVoce, hasLength(20));
    });

    test(
      'com a falha no rodapé, a rolagem não tenta de novo sozinha',
      () async {
        final publicacoesRepo = _FakePublicacoesRepository(
          todas: gerarPublicacoes(25),
        );
        final provider = _criarProvider(publicacoesRepo: publicacoesRepo);
        await provider.trocarAba(AbaFeed.paraVoce);
        publicacoesRepo.falhar = true;
        await provider.carregarMais();
        final antes = publicacoesRepo.chamadas;

        await provider.carregarMais();

        expect(publicacoesRepo.chamadas, antes);
      },
    );

    test('tentar de novo busca a página e limpa a falha', () async {
      final publicacoesRepo = _FakePublicacoesRepository(
        todas: gerarPublicacoes(25),
      );
      final provider = _criarProvider(publicacoesRepo: publicacoesRepo);
      await provider.trocarAba(AbaFeed.paraVoce);
      publicacoesRepo.falhar = true;
      await provider.carregarMais();

      publicacoesRepo.falhar = false;
      await provider.tentarCarregarMaisDeNovo();

      final estado = provider.estadoDe(AbaFeed.paraVoce);
      expect(estado.falhouCarregarMais, isFalse);
      expect(estado.status, StatusAba.sucesso);
      expect(provider.paraVoce, hasLength(25));
    });

    test('pullRefresh limpa a falha do rodapé', () async {
      final publicacoesRepo = _FakePublicacoesRepository(
        todas: gerarPublicacoes(25),
      );
      final provider = _criarProvider(publicacoesRepo: publicacoesRepo);
      await provider.trocarAba(AbaFeed.paraVoce);
      publicacoesRepo.falhar = true;
      await provider.carregarMais();

      publicacoesRepo.falhar = false;
      await provider.pullRefresh();

      expect(provider.estadoDe(AbaFeed.paraVoce).falhouCarregarMais, isFalse);
      expect(provider.paraVoce, hasLength(20));
    });

    test('erro do carregarMais fica na aba que pediu, não na ativa', () async {
      final publicacoesRepo = _FakePublicacoesRepository(
        todas: gerarPublicacoes(25),
      );
      final provider = _criarProvider(publicacoesRepo: publicacoesRepo);
      await provider.trocarAba(AbaFeed.paraVoce);
      publicacoesRepo
        ..falhar = true
        ..segurar = Completer<void>();

      final emVoo = provider.carregarMais();
      await provider.trocarAba(AbaFeed.dicas);
      publicacoesRepo.segurar!.complete();
      await emVoo;

      expect(provider.estadoDe(AbaFeed.paraVoce).falhouCarregarMais, isTrue);
      expect(provider.estadoDe(AbaFeed.dicas).status, StatusAba.sucesso);
      expect(provider.estadoDe(AbaFeed.dicas).falhouCarregarMais, isFalse);
    });

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

  group('FeedProvider - PublicacoesStore', () {
    late PublicacoesStore store;
    late _FakeCurtidasRepository curtidasRepo;
    late AuthProvider authProvider;
    late FeedProvider provider;

    setUp(() async {
      store = PublicacoesStore();
      curtidasRepo = _FakeCurtidasRepository();
      authProvider = AuthProvider(repository: _FakeAuthRepository());
      await authProvider.login(email: 'ana@teste.com', senha: '123456');
      provider = _criarProvider(
        publicacoesRepo: _FakePublicacoesRepository(
          todas: [_publicacao('p1', curtidasCount: 1), _publicacao('p2')],
          seguindoIds: ['p1'],
        ),
        curtidasRepo: curtidasRepo,
        authProvider: authProvider,
        store: store,
      );
      await provider.trocarAba(AbaFeed.paraVoce);
      await provider.trocarAba(AbaFeed.seguindo);
    });

    test('carregar as abas coloca as publicações no store', () {
      expect(store.porId('p1'), isNotNull);
      expect(store.porId('p2'), isNotNull);
    });

    test('curtida feita no store por outra tela aparece nas duas abas', () {
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      store.atualizarCurtida('p1', jaCurtiu: true, curtidasCount: 2);

      expect(notificacoes, greaterThan(0));
      expect(provider.paraVoce.first.jaCurtiu, isTrue);
      expect(provider.paraVoce.first.curtidasCount, 2);
      expect(provider.seguindo.first.jaCurtiu, isTrue);
    });

    test('publicação removida no store some das duas abas', () {
      store.remover('p1');

      expect(provider.paraVoce.map((p) => p.id), ['p2']);
      expect(provider.seguindo, isEmpty);
    });

    test('curtir usa o estado do store, não a cópia antiga da tela', () async {
      final copiaAntiga = provider.paraVoce.first;
      store.atualizarCurtida('p1', jaCurtiu: true, curtidasCount: 2);

      await provider.curtirOuDescurtir(copiaAntiga);

      expect(curtidasRepo.descurtidas, ['p1']);
      expect(curtidasRepo.curtidas, isEmpty);
      expect(store.porId('p1')!.jaCurtiu, isFalse);
      expect(store.porId('p1')!.curtidasCount, 1);
    });

    test('comentário atualiza o contador no store', () {
      provider.atualizarContadorComentarios('p1', 1);

      expect(store.porId('p1')!.comentariosCount, 1);
      expect(provider.seguindo.first.comentariosCount, 1);
    });

    test('publicação criada entra no store e no topo das abas', () {
      final nova = Publicacao(
        id: 'p3',
        autorId: authProvider.usuario!.id,
        autorNome: 'Ana',
        criadoEm: DateTime(2026, 1, 2),
        atualizadoEm: DateTime(2026, 1, 2),
      );

      provider.adicionarPublicacao(nova);

      expect(store.porId('p3'), isNotNull);
      expect(provider.paraVoce.first.id, 'p3');
      expect(provider.seguindo.first.id, 'p3');
    });

    test('dispose deixa de escutar o store', () {
      provider.dispose();

      expect(() => store.upsert(_publicacao('p9')), returnsNormally);
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

  group('FeedProvider - abas presas e troca de conta', () {
    late _FakePublicacoesRepository publicacoesRepo;
    late AuthProvider authProvider;
    late PublicacoesStore store;
    late FeedProvider provider;

    setUp(() async {
      publicacoesRepo = _FakePublicacoesRepository(
        todas: [_publicacao('p1')],
        seguindoIds: ['p1'],
      );
      authProvider = AuthProvider(repository: _FakeAuthRepository());
      await authProvider.login(email: 'ana@teste.com', senha: '123456');
      store = PublicacoesStore();
      provider = _criarProvider(
        publicacoesRepo: publicacoesRepo,
        authProvider: authProvider,
        store: store,
      );
    });

    test('voltar para uma aba em erro carrega de novo', () async {
      publicacoesRepo.falhar = true;
      await provider.trocarAba(AbaFeed.paraVoce);
      expect(provider.estadoDe(AbaFeed.paraVoce).status, StatusAba.erro);

      publicacoesRepo.falhar = false;
      await provider.trocarAba(AbaFeed.eventos);
      await provider.trocarAba(AbaFeed.paraVoce);

      expect(provider.estadoDe(AbaFeed.paraVoce).status, StatusAba.sucesso);
      expect(provider.paraVoce.map((p) => p.id), ['p1']);
    });

    test('voltar para uma aba vazia carrega de novo', () async {
      publicacoesRepo.todas.clear();
      await provider.trocarAba(AbaFeed.paraVoce);
      expect(provider.estadoDe(AbaFeed.paraVoce).status, StatusAba.vazio);

      publicacoesRepo.todas.add(_publicacao('p2'));
      await provider.trocarAba(AbaFeed.eventos);
      await provider.trocarAba(AbaFeed.paraVoce);

      expect(provider.estadoDe(AbaFeed.paraVoce).status, StatusAba.sucesso);
      expect(provider.paraVoce.map((p) => p.id), ['p2']);
    });

    test('logout limpa store, listas e estados de todas as abas', () async {
      await provider.trocarAba(AbaFeed.seguindo);
      await provider.trocarAba(AbaFeed.eventos);
      await provider.trocarAba(AbaFeed.paraVoce);
      publicacoesRepo.segurar = Completer<void>();

      await authProvider.signOut();
      provider.reagirAuth(authProvider);

      expect(store.porId('p1'), isNull);
      expect(provider.paraVoce, isEmpty);
      expect(provider.seguindo, isEmpty);
      expect(provider.estadoDe(AbaFeed.paraVoce).status, StatusAba.carregando);
      for (final aba in [AbaFeed.seguindo, AbaFeed.eventos, AbaFeed.locais]) {
        expect(
          provider.estadoDe(aba).status,
          StatusAba.inicial,
          reason: '$aba',
        );
      }
    });

    test('logout recarrega a aba ativa', () async {
      await provider.trocarAba(AbaFeed.paraVoce);
      final antes = publicacoesRepo.chamadas;

      await authProvider.signOut();
      provider.reagirAuth(authProvider);
      await pumpEventQueue();

      expect(publicacoesRepo.chamadas, antes + 1);
      expect(provider.estadoDe(AbaFeed.paraVoce).status, StatusAba.sucesso);
      expect(store.porId('p1'), isNotNull);
    });

    test('login recarrega a Para você carregada sem conta', () async {
      await authProvider.signOut();
      provider.reagirAuth(authProvider);
      await pumpEventQueue();
      final antes = publicacoesRepo.chamadas;

      await authProvider.login(email: 'ana@teste.com', senha: '123456');
      provider.reagirAuth(authProvider);
      await pumpEventQueue();

      expect(publicacoesRepo.chamadas, antes + 1);
      expect(provider.estadoDe(AbaFeed.paraVoce).status, StatusAba.sucesso);
    });

    test('trocarAba durante a carga do login espera a mesma chamada', () async {
      await authProvider.signOut();
      provider.reagirAuth(authProvider);
      await pumpEventQueue();
      final antes = publicacoesRepo.chamadas;
      publicacoesRepo.segurar = Completer<void>();

      await authProvider.login(email: 'ana@teste.com', senha: '123456');
      provider.reagirAuth(authProvider);
      var terminou = false;
      final troca = provider
          .trocarAba(AbaFeed.paraVoce)
          .then((_) => terminou = true);
      await pumpEventQueue();

      expect(publicacoesRepo.chamadas, antes + 1);
      expect(terminou, isFalse);

      publicacoesRepo.segurar!.complete();
      await troca;

      expect(publicacoesRepo.chamadas, antes + 1);
      expect(provider.estadoDe(AbaFeed.paraVoce).status, StatusAba.sucesso);
    });

    test('resposta que chega depois do logout é descartada', () async {
      publicacoesRepo.segurar = Completer<void>();
      final emVoo = provider.trocarAba(AbaFeed.seguindo);

      await authProvider.signOut();
      provider.reagirAuth(authProvider);
      publicacoesRepo.segurar!.complete();
      await emVoo;

      expect(provider.seguindo, isEmpty);
      expect(provider.estadoDe(AbaFeed.seguindo).status, StatusAba.vazio);
    });

    test('atualizar o próprio usuário não reinicia o feed', () async {
      await provider.trocarAba(AbaFeed.paraVoce);
      final antes = publicacoesRepo.chamadas;

      authProvider.atualizarUsuario(
        authProvider.usuario!.copyWith(bio: 'Nova bio'),
      );
      provider.reagirAuth(authProvider);

      expect(publicacoesRepo.chamadas, antes);
      expect(provider.paraVoce.map((p) => p.id), ['p1']);
      expect(store.porId('p1'), isNotNull);
    });
  });

  group('FeedProvider - eventos realtime de publicações', () {
    late FakeRealtimeManager realtime;
    late PublicacoesStore store;
    late AuthProvider authProvider;
    late FeedProvider provider;

    setUp(() async {
      realtime = FakeRealtimeManager(conectado: true);
      store = PublicacoesStore();
      authProvider = AuthProvider(repository: _FakeAuthRepository());
      await authProvider.login(email: 'ana@teste.com', senha: '123456');
      provider = _criarProvider(
        publicacoesRepo: _FakePublicacoesRepository(
          todas: [
            _publicacao(
              'p1',
              curtidasCount: 3,
              jaCurtiu: true,
              comentariosCount: 2,
            ),
            _publicacao('p2'),
          ],
          seguindoIds: ['p1'],
        ),
        authProvider: authProvider,
        realtime: realtime,
        store: store,
      );
      await provider.trocarAba(AbaFeed.paraVoce);
      await provider.trocarAba(AbaFeed.seguindo);
    });

    test('publicacao_removida tira a publicação do store e das duas abas', () {
      realtime.emitir('publicacao_removida', {
        'publicacaoId': 'p1',
        'autorId': 'autor-p1',
      });

      expect(store.foiRemovida('p1'), isTrue);
      expect(provider.paraVoce.map((p) => p.id), ['p2']);
      expect(provider.seguindo, isEmpty);
    });

    test('publicacao_curtidas de outra pessoa atualiza o contador no Feed', () {
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      realtime.emitir('publicacao_curtidas', {
        'publicacaoId': 'p1',
        'curtidasCount': 9,
        'porId': 'outra-pessoa',
      });

      expect(notificacoes, greaterThan(0));
      expect(provider.paraVoce.first.curtidasCount, 9);
      expect(provider.seguindo.first.curtidasCount, 9);
    });

    test('curtida de outra pessoa não muda o meu jaCurtiu', () {
      realtime.emitir('publicacao_curtidas', {
        'publicacaoId': 'p1',
        'curtidasCount': 4,
        'porId': 'outra-pessoa',
      });

      expect(store.porId('p1')!.jaCurtiu, isTrue);
      expect(store.porId('p1')!.curtidasCount, 4);
    });

    test(
      'publicacao_comentarios de outra pessoa atualiza o contador no Feed',
      () {
        realtime.emitir('publicacao_comentarios', {
          'publicacaoId': 'p1',
          'comentariosCount': 6,
          'porId': 'outra-pessoa',
        });

        expect(provider.paraVoce.first.comentariosCount, 6);
        expect(provider.seguindo.first.comentariosCount, 6);
      },
    );

    test('eco da própria curtida e do próprio comentário é ignorado', () {
      final meuId = authProvider.usuario!.id;

      realtime.emitir('publicacao_curtidas', {
        'publicacaoId': 'p1',
        'curtidasCount': 99,
        'porId': meuId,
      });
      realtime.emitir('publicacao_comentarios', {
        'publicacaoId': 'p1',
        'comentariosCount': 99,
        'porId': meuId,
      });

      expect(store.porId('p1')!.curtidasCount, 3);
      expect(store.porId('p1')!.comentariosCount, 2);
    });

    test(
      'o eco usa o usuário logado na hora do evento, não o da assinatura',
      () async {
        await authProvider.signOut();
        provider.reagirAuth(authProvider);
        await pumpEventQueue();
        store.upsert(_publicacao('p1', curtidasCount: 3));

        realtime.emitir('publicacao_curtidas', {
          'publicacaoId': 'p1',
          'curtidasCount': 5,
          'porId': 'u1',
        });

        expect(store.porId('p1')!.curtidasCount, 5);
      },
    );

    test('contador de publicação fora do store é ignorado', () {
      var notificacoes = 0;
      store.addListener(() => notificacoes++);

      realtime.emitir('publicacao_curtidas', {
        'publicacaoId': 'desconhecida',
        'curtidasCount': 5,
        'porId': 'outra-pessoa',
      });
      realtime.emitir('publicacao_comentarios', {
        'publicacaoId': 'desconhecida',
        'comentariosCount': 5,
        'porId': 'outra-pessoa',
      });

      expect(store.porId('desconhecida'), isNull);
      expect(notificacoes, 0);
    });

    test('payload inválido é ignorado', () {
      final invalidos = <String, List<dynamic>>{
        'publicacao_removida': [
          null,
          'p1',
          <String, dynamic>{},
          {'publicacaoId': 1, 'autorId': 'autor-p1'},
          {'publicacaoId': 'p1'},
        ],
        'publicacao_curtidas': [
          null,
          {'publicacaoId': 'p1', 'porId': 'outra-pessoa'},
          {'publicacaoId': 'p1', 'curtidasCount': '9', 'porId': 'outra-pessoa'},
          {'publicacaoId': 'p1', 'curtidasCount': -1, 'porId': 'outra-pessoa'},
          {'publicacaoId': 'p1', 'curtidasCount': 9},
          {'curtidasCount': 9, 'porId': 'outra-pessoa'},
        ],
        'publicacao_comentarios': [
          null,
          {
            'publicacaoId': 'p1',
            'comentariosCount': 9.5,
            'porId': 'outra-pessoa',
          },
          {'publicacaoId': 'p1', 'comentariosCount': 9, 'porId': 7},
        ],
      };

      for (final MapEntry(key: evento, value: payloads) in invalidos.entries) {
        for (final payload in payloads) {
          realtime.emitir(evento, payload);
        }
      }

      final p1 = store.porId('p1')!;
      expect(store.foiRemovida('p1'), isFalse);
      expect(p1.curtidasCount, 3);
      expect(p1.comentariosCount, 2);
    });

    test('dispose desfaz as assinaturas dos eventos de publicação', () {
      for (final evento in [
        'publicacao_removida',
        'publicacao_curtidas',
        'publicacao_comentarios',
      ]) {
        expect(realtime.assinantes[evento], hasLength(1), reason: evento);
      }

      provider.dispose();

      for (final evento in [
        'publicacao_removida',
        'publicacao_curtidas',
        'publicacao_comentarios',
      ]) {
        expect(realtime.assinantes[evento], isEmpty, reason: evento);
      }
    });
  });

  group('FeedProvider - publicacao_criada (Para você)', () {
    late List<Publicacao> todas;
    late _FakePublicacoesRepository publicacoesRepo;
    late AuthProvider authProvider;
    late FakeRealtimeManager realtime;
    late FeedProvider provider;

    void publicarNoServidor(String id) => todas.insert(0, _publicacao(id));

    Map<String, dynamic> criada(String id, {String autorId = 'autor-x'}) => {
      'publicacaoId': id,
      'autorId': autorId,
      'timestamp': '2026-11-06T12:00:00.000Z',
    };

    setUp(() async {
      todas = [_publicacao('p1'), _publicacao('p2')];
      publicacoesRepo = _FakePublicacoesRepository(todas: todas);
      authProvider = AuthProvider(repository: _FakeAuthRepository());
      await authProvider.login(email: 'ana@teste.com', senha: '123456');
      realtime = FakeRealtimeManager();
      provider = _criarProvider(
        publicacoesRepo: publicacoesRepo,
        authProvider: authProvider,
        realtime: realtime,
      );
      await provider.trocarAba(AbaFeed.paraVoce);
    });

    test('evento de outro autor entra nos pendentes e notifica', () {
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      realtime.emitir('publicacao_criada', criada('p3'));

      expect(provider.pendentesParaVoceCount, 1);
      expect(notificacoes, 1);
    });

    test('evento do próprio usuário é no-op', () {
      realtime.emitir('publicacao_criada', criada('p3', autorId: 'u1'));

      expect(provider.pendentesParaVoceCount, 0);
    });

    test('publicação já na lista ou repetida não conta de novo', () {
      realtime.emitir('publicacao_criada', criada('p1'));
      expect(provider.pendentesParaVoceCount, 0);

      realtime.emitir('publicacao_criada', criada('p3'));
      realtime.emitir('publicacao_criada', criada('p3'));
      expect(provider.pendentesParaVoceCount, 1);
    });

    test('payload malformado é ignorado', () {
      realtime.emitir('publicacao_criada', 'lixo');
      realtime.emitir('publicacao_criada', {'publicacaoId': 3});
      realtime.emitir('publicacao_criada', {'publicacaoId': 'p3'});

      expect(provider.pendentesParaVoceCount, 0);
    });

    test('pendentes da Para você e da Seguindo não se misturam', () {
      realtime.emitir('publicacao_criada', criada('p3'));
      realtime.emitir('nova_publicacao_feed', _novaPublicacao('p4'));

      expect(provider.pendentesParaVoceCount, 1);
      expect(provider.pendentesSeguindoCount, 1);
    });

    test(
      'aplicarPendentesParaVoce busca a página 1 e faz prepend sem duplicar',
      () async {
        publicarNoServidor('p3');
        publicarNoServidor('p4');
        realtime.emitir('publicacao_criada', criada('p3'));
        realtime.emitir('publicacao_criada', criada('p4'));
        final chamadasAntes = publicacoesRepo.chamadas;

        await provider.aplicarPendentesParaVoce();

        expect(publicacoesRepo.chamadas, chamadasAntes + 1);
        expect(provider.paraVoce.map((p) => p.id), ['p4', 'p3', 'p1', 'p2']);
        expect(provider.pendentesParaVoceCount, 0);
        expect(provider.estadoDe(AbaFeed.paraVoce).status, StatusAba.sucesso);
      },
    );

    test(
      'aplicarPendentesParaVoce sem pendentes não chama o repositório',
      () async {
        final chamadasAntes = publicacoesRepo.chamadas;

        await provider.aplicarPendentesParaVoce();

        expect(publicacoesRepo.chamadas, chamadasAntes);
      },
    );

    test('aplicarPendentesParaVoce descarta a resposta após logout', () async {
      publicarNoServidor('p3');
      realtime.emitir('publicacao_criada', criada('p3'));
      final segurada = Completer<void>();
      publicacoesRepo.segurar = segurada;
      final aplicando = provider.aplicarPendentesParaVoce();

      publicacoesRepo.segurar = null;
      await authProvider.signOut();
      provider.reagirAuth(authProvider);
      await pumpEventQueue();
      expect(provider.paraVoce.map((p) => p.id), ['p3', 'p1', 'p2']);

      publicarNoServidor('p9');
      segurada.complete();
      await aplicando;

      expect(provider.paraVoce.map((p) => p.id), [
        'p3',
        'p1',
        'p2',
      ], reason: 'a resposta da sessão anterior não pode fazer prepend');
    });

    test('pullRefresh zera os pendentes', () async {
      realtime.emitir('publicacao_criada', criada('p3'));

      await provider.pullRefresh();

      expect(provider.pendentesParaVoceCount, 0);
    });

    test('carregamento inicial da Para você zera os pendentes', () async {
      final outro = _criarProvider(
        publicacoesRepo: publicacoesRepo,
        authProvider: authProvider,
        realtime: realtime,
      );
      realtime.emitir('publicacao_criada', criada('p3'));
      expect(outro.pendentesParaVoceCount, 1);

      await outro.trocarAba(AbaFeed.paraVoce);

      expect(outro.pendentesParaVoceCount, 0);
    });

    test('logout e login zeram os pendentes', () async {
      realtime.emitir('publicacao_criada', criada('p3'));
      await authProvider.signOut();
      provider.reagirAuth(authProvider);
      expect(provider.pendentesParaVoceCount, 0);
      await pumpEventQueue();

      realtime.emitir('publicacao_criada', criada('p4'));
      await authProvider.login(email: 'ana@teste.com', senha: '123456');
      provider.reagirAuth(authProvider);

      expect(provider.pendentesParaVoceCount, 0);
    });

    test('reconexão zera os pendentes', () {
      realtime.emitir('publicacao_criada', criada('p3'));

      realtime.simularReconexao();

      expect(provider.pendentesParaVoceCount, 0);
    });

    test('dispose desfaz a assinatura do publicacao_criada', () {
      expect(realtime.assinantes['publicacao_criada'], hasLength(1));

      provider.dispose();

      expect(realtime.assinantes['publicacao_criada'], isEmpty);
    });
  });

  group('FeedProvider - reconexão do realtime', () {
    late List<Publicacao> todas;
    late List<String> seguindoIds;
    late _FakePublicacoesRepository publicacoesRepo;
    late AuthProvider authProvider;
    late FakeRealtimeManager realtime;
    late PublicacoesStore store;
    late FeedProvider provider;

    setUp(() async {
      todas = List.generate(25, (i) => _publicacao('p$i'));
      seguindoIds = todas.map((p) => p.id).toList();
      publicacoesRepo = _FakePublicacoesRepository(
        todas: todas,
        seguindoIds: seguindoIds,
      );
      authProvider = AuthProvider(repository: _FakeAuthRepository());
      await authProvider.login(email: 'ana@teste.com', senha: '123456');
      realtime = FakeRealtimeManager();
      store = PublicacoesStore();
      provider = _criarProvider(
        publicacoesRepo: publicacoesRepo,
        authProvider: authProvider,
        realtime: realtime,
        store: store,
      );
      await provider.trocarAba(AbaFeed.paraVoce);
      await provider.carregarMais();
    });

    test(
      'Para você: mescla a página 1 sem perder o que já foi carregado',
      () async {
        expect(provider.paraVoce, hasLength(25));
        todas.insert(0, _publicacao('nova'));
        todas[1] = _publicacao('p0', curtidasCount: 9, comentariosCount: 4);
        final chamadasAntes = publicacoesRepo.chamadas;

        realtime.simularReconexao();
        await pumpEventQueue();

        expect(publicacoesRepo.chamadas, chamadasAntes + 1);
        final ids = provider.paraVoce.map((p) => p.id).toList();
        expect(ids.first, 'nova');
        expect(ids, hasLength(26));
        expect(ids.toSet(), hasLength(26));
        expect(store.porId('p0')!.curtidasCount, 9);
        expect(store.porId('p0')!.comentariosCount, 4);
        expect(provider.estadoDe(AbaFeed.paraVoce).status, StatusAba.sucesso);
      },
    );

    test('Para você: a paginação continua de onde estava', () async {
      todas.insert(0, _publicacao('nova'));
      realtime.simularReconexao();
      await pumpEventQueue();
      final chamadasAntes = publicacoesRepo.chamadas;

      await provider.carregarMais();

      expect(
        publicacoesRepo.chamadas,
        chamadasAntes,
        reason: 'as 25 já foram carregadas; a mescla não reabre a paginação',
      );
    });

    test('Seguindo: também mescla a página 1', () async {
      await provider.trocarAba(AbaFeed.seguindo);
      todas.insert(0, _publicacao('nova-seg'));
      seguindoIds.add('nova-seg');

      realtime.simularReconexao();
      await pumpEventQueue();

      expect(provider.seguindo.first.id, 'nova-seg');
    });

    test('outra aba ativa: não busca nada', () async {
      await provider.trocarAba(AbaFeed.eventos);
      final chamadasAntes = publicacoesRepo.chamadas;

      realtime.simularReconexao();
      await pumpEventQueue();

      expect(publicacoesRepo.chamadas, chamadasAntes);
    });

    test('aba ativa ainda não carregada: não busca nada', () async {
      final outro = _criarProvider(
        publicacoesRepo: publicacoesRepo,
        authProvider: authProvider,
        realtime: realtime,
      );
      expect(outro.estadoDe(AbaFeed.paraVoce).status, StatusAba.inicial);
      provider.dispose();
      final chamadasAntes = publicacoesRepo.chamadas;

      realtime.simularReconexao();
      await pumpEventQueue();

      expect(publicacoesRepo.chamadas, chamadasAntes);
    });

    test('Seguindo sem conta: não busca nada', () async {
      await authProvider.signOut();
      provider.reagirAuth(authProvider);
      await pumpEventQueue();
      await provider.trocarAba(AbaFeed.seguindo);
      final chamadasAntes = publicacoesRepo.chamadas;

      realtime.simularReconexao();
      await pumpEventQueue();

      expect(publicacoesRepo.chamadas, chamadasAntes);
    });

    test('não apaga o erro do rodapé do carregar mais', () async {
      todas.addAll(List.generate(20, (i) => _publicacao('extra$i')));
      await provider.pullRefresh();
      await provider.carregarMais();
      publicacoesRepo.falhar = true;
      await provider.carregarMais();
      expect(provider.estadoDe(AbaFeed.paraVoce).falhouCarregarMais, isTrue);
      publicacoesRepo.falhar = false;

      realtime.simularReconexao();
      await pumpEventQueue();

      expect(provider.estadoDe(AbaFeed.paraVoce).falhouCarregarMais, isTrue);
    });

    test(
      'resposta que chega depois de uma troca de conta é descartada',
      () async {
        final segurada = Completer<void>();
        publicacoesRepo.segurar = segurada;
        realtime.simularReconexao();

        publicacoesRepo.segurar = null;
        await authProvider.signOut();
        provider.reagirAuth(authProvider);
        await pumpEventQueue();
        final depoisDaRecarga = provider.paraVoce.map((p) => p.id).toList();

        todas.insert(0, _publicacao('da-sessao-antiga'));
        segurada.complete();
        await pumpEventQueue();

        expect(provider.paraVoce.map((p) => p.id).toList(), depoisDaRecarga);
      },
    );
  });
}
