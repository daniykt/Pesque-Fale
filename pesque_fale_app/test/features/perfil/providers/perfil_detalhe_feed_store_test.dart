import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/feed/domain/aba_feed.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/perfil/providers/perfil_provider.dart';
import 'package:pesque_fale_app/features/visualizacao_post/providers/publicacao_detalhe_provider.dart';

import '../support/fakes_perfil_detalhe.dart';

/// Perfil, feed e detalhe ligados pelo mesmo PublicacoesStore, como no app.
/// O detalhe é aberto com a publicação que veio da galeria do perfil e faz o
/// que a tela faz: curte pelo FeedProvider (AcoesBar) e comenta pelo
/// aplicarDeltaComentarios (ComentariosLista.onCountChange).
void main() {
  late PublicacoesStore store;
  late AuthProvider auth;
  late FakeCurtidasRepository curtidasRepo;
  late FakePublicacoesRepository publicacoesRepo;
  late FeedProvider feed;
  late PerfilProvider perfil;
  late PublicacaoDetalheProvider detalhe;

  // O mesmo post no feed e no perfil, com contadores distintos de zero para
  // um +1 errado não passar por acaso.
  final p1 = publicacaoDoEu(
    'p1',
    dia: 2,
    descricao: 'Tucunaré no rio Mogi',
    curtidasCount: 3,
    comentariosCount: 5,
  );
  final p2 = publicacaoDoEu('p2', dia: 1);

  setUp(() async {
    store = PublicacoesStore();
    auth = await authLogado();
    curtidasRepo = FakeCurtidasRepository();
    publicacoesRepo = FakePublicacoesRepository(feed: [p1, p2]);

    feed = criarFeedProvider(
      publicacoesRepo: publicacoesRepo,
      curtidasRepo: curtidasRepo,
      authProvider: auth,
      store: store,
    );
    await feed.trocarAba(AbaFeed.paraVoce);

    perfil = PerfilProvider(
      repository: FakePerfilRepository(publicacoes: [p1, p2]),
      authProvider: auth,
      store: store,
    );
    await perfil.carregarPerfil(idEu);

    // Abre como a galeria abre: com a publicação da lista do perfil.
    detalhe = PublicacaoDetalheProvider(
      publicacoesRepository: publicacoesRepo,
      store: store,
      publicacaoInicial: perfil.publicacoes.firstWhere((p) => p.id == 'p1'),
    );
    await detalhe.carregar();
  });

  tearDown(() {
    detalhe.dispose();
    perfil.dispose();
    feed.dispose();
  });

  Publicacao noPerfil() => perfil.publicacoes.firstWhere((p) => p.id == 'p1');
  Publicacao noFeed() => feed.paraVoce.firstWhere((p) => p.id == 'p1');

  void esperarEmTodos({
    required bool jaCurtiu,
    required int curtidas,
    required int comentarios,
  }) {
    for (final (onde, p) in [
      ('perfil', noPerfil()),
      ('feed', noFeed()),
      ('detalhe', detalhe.publicacao!),
    ]) {
      expect(p.jaCurtiu, jaCurtiu, reason: 'jaCurtiu no $onde');
      expect(p.curtidasCount, curtidas, reason: 'curtidas no $onde');
      expect(p.comentariosCount, comentarios, reason: 'comentários no $onde');
    }
  }

  test('ponto de partida: o mesmo p1 no perfil, no feed e no detalhe', () {
    expect(detalhe.status, StatusDetalhe.carregado);
    expect(publicacoesRepo.buscasPorId, 0);
    esperarEmTodos(jaCurtiu: false, curtidas: 3, comentarios: 5);
  });

  test('curtir no detalhe aberto pela galeria reflete no perfil e no feed '
      'sem recarregar', () async {
    var notificacoesPerfil = 0;
    var notificacoesFeed = 0;
    perfil.addListener(() => notificacoesPerfil++);
    feed.addListener(() => notificacoesFeed++);

    await feed.curtirOuDescurtir(detalhe.publicacao!);

    expect(curtidasRepo.curtidas, ['p1']);
    esperarEmTodos(jaCurtiu: true, curtidas: 4, comentarios: 5);
    expect(notificacoesPerfil, greaterThan(0));
    expect(notificacoesFeed, greaterThan(0));

    await feed.curtirOuDescurtir(detalhe.publicacao!);

    expect(curtidasRepo.descurtidas, ['p1']);
    esperarEmTodos(jaCurtiu: false, curtidas: 3, comentarios: 5);
  });

  test('comentar no detalhe reflete no perfil e no feed', () {
    var notificacoesPerfil = 0;
    var notificacoesFeed = 0;
    perfil.addListener(() => notificacoesPerfil++);
    feed.addListener(() => notificacoesFeed++);

    detalhe.aplicarDeltaComentarios(1);

    esperarEmTodos(jaCurtiu: false, curtidas: 3, comentarios: 6);
    expect(notificacoesPerfil, greaterThan(0));
    expect(notificacoesFeed, greaterThan(0));
  });

  test('curtir e depois comentar no detalhe: o upsert do comentário não '
      'desfaz a curtida', () async {
    await feed.curtirOuDescurtir(detalhe.publicacao!);
    detalhe.aplicarDeltaComentarios(1);

    esperarEmTodos(jaCurtiu: true, curtidas: 4, comentarios: 6);
    expect(store.porId('p1')!.jaCurtiu, isTrue);
  });

  test('o outro post não muda', () async {
    await feed.curtirOuDescurtir(detalhe.publicacao!);
    detalhe.aplicarDeltaComentarios(1);

    final outro = perfil.publicacoes.firstWhere((p) => p.id == 'p2');
    expect(outro.jaCurtiu, isFalse);
    expect(outro.curtidasCount, 0);
    expect(outro.comentariosCount, 0);
  });
}
