import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/notificacoes/data/notificacoes_repository.dart';
import 'package:pesque_fale_app/features/notificacoes/domain/notificacao.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository_mock.dart';

Notificacao _notificacao(String id) => Notificacao(
  id: id,
  para: 'me',
  tipo: TipoNotificacao.sistema,
  texto: 'Notificação $id',
  lida: true,
  criadoEm: DateTime(2026, 9, 1),
);

class _FakeNotificacoesRepository implements NotificacoesRepository {
  List<Notificacao> servidor = [
    _notificacao('n1'),
    _notificacao('n2'),
    _notificacao('n3'),
  ];
  final List<String> apagadas = [];
  bool falharApagar = false;
  bool falharApagarTodas = false;

  @override
  Future<({List<Notificacao> lista, int naoLidas})> listar({
    int pagina = 1,
    int porPagina = 20,
  }) async => (lista: List<Notificacao>.unmodifiable(servidor), naoLidas: 0);

  @override
  Future<int> contarNaoLidas() async => 0;

  @override
  Future<void> marcarTodasComoLidas() async {}

  @override
  Future<void> apagar(String id) async {
    if (falharApagar) throw Exception('falha');
    apagadas.add(id);
    servidor = servidor.where((n) => n.id != id).toList();
  }

  @override
  Future<void> apagarTodas() async {
    if (falharApagarTodas) throw Exception('falha');
    servidor = [];
  }
}

void main() {
  late _FakeNotificacoesRepository repo;
  late NotificacoesProvider provider;

  List<String> ids() => provider.notificacoes.map((n) => n.id).toList();

  setUp(() async {
    repo = _FakeNotificacoesRepository();
    provider = NotificacoesProvider(
      repository: repo,
      perfilRepository: PerfilRepositoryMock(),
    );
    await provider.carregar();
  });

  test('removerLocal tira o item da lista sem chamar a API', () {
    final removeu = provider.removerLocal('n2');

    expect(removeu, isTrue);
    expect(ids(), ['n1', 'n3']);
    expect(repo.apagadas, isEmpty);
  });

  test('removerLocal retorna false para um id que não está na lista', () {
    expect(provider.removerLocal('nao-existe'), isFalse);
    expect(ids(), ['n1', 'n2', 'n3']);
  });

  test('desfazerRemocao devolve o item na posição original', () {
    provider.removerLocal('n2');

    provider.desfazerRemocao('n2');

    expect(ids(), ['n1', 'n2', 'n3']);
  });

  test('confirmarRemocao apaga na API', () async {
    provider.removerLocal('n2');

    final apagou = await provider.confirmarRemocao('n2');

    expect(apagou, isTrue);
    expect(repo.apagadas, ['n2']);
    expect(ids(), ['n1', 'n3']);
  });

  test('confirmarRemocao depois do desfazer não chama a API', () async {
    provider.removerLocal('n2');
    provider.desfazerRemocao('n2');

    final apagou = await provider.confirmarRemocao('n2');

    expect(apagou, isTrue);
    expect(repo.apagadas, isEmpty);
    expect(ids(), ['n1', 'n2', 'n3']);
  });

  test('confirmarRemocao com falha na API devolve o item para a lista', () async {
    repo.falharApagar = true;
    provider.removerLocal('n2');

    final apagou = await provider.confirmarRemocao('n2');

    expect(apagou, isFalse);
    expect(ids(), ['n1', 'n2', 'n3']);
  });

  test('refresh não traz de volta um item com remoção pendente', () async {
    provider.removerLocal('n2');

    await provider.refresh();

    expect(ids(), ['n1', 'n3']);
  });

  test('limparTodas apaga na API e esvazia a lista', () async {
    final limpou = await provider.limparTodas();

    expect(limpou, isTrue);
    expect(provider.temAlguma, isFalse);
    expect(repo.servidor, isEmpty);
  });

  test('limparTodas com falha na API mantém a lista', () async {
    repo.falharApagarTodas = true;

    final limpou = await provider.limparTodas();

    expect(limpou, isFalse);
    expect(ids(), ['n1', 'n2', 'n3']);
  });

  test('não notifica depois de descartado', () async {
    provider.removerLocal('n2');
    repo.falharApagar = true;
    provider.dispose();

    expect(await provider.confirmarRemocao('n2'), isFalse);
  });
}