import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/core/data/paged_result.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_exceptions.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/visualizacao_post/providers/publicacao_detalhe_provider.dart';

class _FakePublicacoesRepository implements PublicacoesRepository {
  _FakePublicacoesRepository({this.remota});

  final Publicacao? remota;
  bool falharDeletar = false;
  int buscas = 0;
  final List<String> deletadas = [];

  @override
  Future<Publicacao> buscarPorId(String id) async {
    buscas++;
    return remota!;
  }

  @override
  Future<void> deletar(String id) async {
    if (falharDeletar) throw const InternalServerException();
    deletadas.add(id);
  }

  @override
  Future<PagedResult<Publicacao>> listar({
    int pagina = 1,
    int porPagina = 20,
    bool seguindo = false,
  }) => throw UnimplementedError();

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

Publicacao _publicacao({int comentariosCount = 0}) => Publicacao(
  id: 'p1',
  autorId: 'autor-1',
  autorNome: 'Ana',
  comentariosCount: comentariosCount,
  criadoEm: DateTime(2026, 1, 1),
  atualizadoEm: DateTime(2026, 1, 1),
);

void main() {
  late PublicacoesStore store;
  late _FakePublicacoesRepository repo;

  setUp(() {
    store = PublicacoesStore();
    repo = _FakePublicacoesRepository(remota: _publicacao());
  });

  PublicacaoDetalheProvider criar({Publicacao? inicial, String? id}) =>
      PublicacaoDetalheProvider(
        publicacoesRepository: repo,
        store: store,
        publicacaoInicial: inicial,
        publicacaoId: id,
      );

  test('com publicação inicial carrega sem chamar a API', () async {
    final provider = criar(inicial: _publicacao());

    await provider.carregar();

    expect(provider.status, StatusDetalhe.carregado);
    expect(repo.buscas, 0);
  });

  test('só com id busca na API e coloca no store', () async {
    final provider = criar(id: 'p1');

    await provider.carregar();

    expect(provider.status, StatusDetalhe.carregado);
    expect(store.porId('p1'), isNotNull);
  });

  test('reflete a curtida feita em outra tela', () async {
    store.upsert(_publicacao());
    final provider = criar(inicial: _publicacao());
    await provider.carregar();
    var notificacoes = 0;
    provider.addListener(() => notificacoes++);

    store.atualizarCurtida('p1', jaCurtiu: true, curtidasCount: 1);

    expect(notificacoes, 1);
    expect(provider.publicacao!.jaCurtiu, isTrue);
    expect(provider.publicacao!.curtidasCount, 1);
  });

  test('comentário atualiza o contador no store', () async {
    store.upsert(_publicacao(comentariosCount: 2));
    final provider = criar(inicial: _publicacao(comentariosCount: 2));

    provider.aplicarDeltaComentarios(1);

    expect(store.porId('p1')!.comentariosCount, 3);
    expect(provider.publicacao!.comentariosCount, 3);
  });

  test('comentário em publicação que ainda não está no store a coloca lá', () {
    final provider = criar(inicial: _publicacao(comentariosCount: 2));

    provider.aplicarDeltaComentarios(1);

    expect(store.porId('p1')!.comentariosCount, 3);
  });

  test('excluir apaga na API e remove do store', () async {
    store.upsert(_publicacao());
    final provider = criar(inicial: _publicacao());
    await provider.carregar();

    await provider.excluir();

    expect(repo.deletadas, ['p1']);
    expect(store.foiRemovida('p1'), isTrue);
    expect(provider.status, StatusDetalhe.removida);
    expect(provider.excluidaAqui, isTrue);
    expect(provider.excluindo, isFalse);
  });

  test('excluir com erro mantém a publicação no store', () async {
    store.upsert(_publicacao());
    repo.falharDeletar = true;
    final provider = criar(inicial: _publicacao());
    await provider.carregar();

    await expectLater(
      provider.excluir(),
      throwsA(isA<InternalServerException>()),
    );

    expect(store.porId('p1'), isNotNull);
    expect(provider.status, StatusDetalhe.carregado);
    expect(provider.excluindo, isFalse);
  });

  test('publicação removida em outra tela vira status removida', () async {
    store.upsert(_publicacao());
    final provider = criar(inicial: _publicacao());
    await provider.carregar();

    store.remover('p1');

    expect(provider.status, StatusDetalhe.removida);
    expect(provider.excluidaAqui, isFalse);
    expect(provider.publicacao, isNotNull);
  });

  test('abrir publicação já removida não chama a API', () async {
    store.remover('p1');
    final provider = criar(id: 'p1');

    await provider.carregar();

    expect(provider.status, StatusDetalhe.removida);
    expect(repo.buscas, 0);
  });

  test('dispose deixa de escutar o store', () {
    final provider = criar(inicial: _publicacao());

    provider.dispose();

    expect(() => store.upsert(_publicacao()), returnsNormally);
  });
}
