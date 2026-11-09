import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/notificacoes/data/notificacoes_repository.dart';
import 'package:pesque_fale_app/features/notificacoes/domain/notificacao.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/badge_notificacoes_provider.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository_mock.dart';

import '../../chat/support/fake_realtime_manager.dart';

Notificacao _notif(String id, {required bool lida}) => Notificacao(
  id: id,
  para: 'me',
  tipo: TipoNotificacao.curtida,
  lida: lida,
  criadoEm: DateTime(2026, 10, 1),
);

Map<String, dynamic> _payload(String id) => {
  'id': id,
  'para': 'me',
  'deId': 'user-a',
  'de': 'Fulano',
  'deUsername': 'fulano',
  'tipo': 'curtida',
  'postId': 'pub-1',
  'lida': false,
  'criadoEm': '2026-10-27T12:00:00.000Z',
};

class _FakeNotificacoesRepository implements NotificacoesRepository {
  List<Notificacao> servidor = const [];

  @override
  Future<({List<Notificacao> lista, int naoLidas})> listar({
    int pagina = 1,
    int porPagina = 20,
  }) async => (lista: servidor, naoLidas: 0);

  @override
  Future<int> contarNaoLidas() async => 0;

  @override
  Future<void> marcarTodasComoLidas() async {}

  @override
  Future<void> apagar(String id) async {}

  @override
  Future<void> apagarTodas() async {}
}

void main() {
  late _FakeNotificacoesRepository repo;
  late FakeRealtimeManager realtime;
  late NotificacoesProvider notificacoesProvider;
  late BadgeNotificacoesProvider provider;
  late int notificacoes;

  setUp(() {
    repo = _FakeNotificacoesRepository();
    realtime = FakeRealtimeManager();
    notificacoesProvider = NotificacoesProvider(
      repository: repo,
      perfilRepository: PerfilRepositoryMock(),
      realtime: realtime,
    );
    provider = BadgeNotificacoesProvider(notificacoes: notificacoesProvider);
    notificacoes = 0;
    provider.addListener(() => notificacoes++);
  });

  test('conta as não lidas quando a lista do provider carrega', () async {
    repo.servidor = [
      _notif('a', lida: false),
      _notif('b', lida: true),
      _notif('c', lida: false),
    ];

    await notificacoesProvider.carregar();

    expect(provider.naoLidas, 2);
    expect(notificacoes, 1);
  });

  test('já nasce com a contagem do provider', () async {
    repo.servidor = [_notif('a', lida: false)];
    await notificacoesProvider.carregar();

    final outro = BadgeNotificacoesProvider(notificacoes: notificacoesProvider);

    expect(outro.naoLidas, 1);
  });

  test('sobe quando chega nova_notificacao em tempo real', () async {
    await notificacoesProvider.carregar();
    expect(provider.naoLidas, 0);

    realtime.emitir('nova_notificacao', _payload('n1'));
    expect(provider.naoLidas, 1);

    realtime.emitir('nova_notificacao', _payload('n2'));
    expect(provider.naoLidas, 2);
  });

  test('zera quando a aba Alertas abre e marca como lidas', () async {
    repo.servidor = [_notif('a', lida: false), _notif('b', lida: false)];
    await notificacoesProvider.carregar();
    expect(provider.naoLidas, 2);

    await notificacoesProvider.carregar(marcarComoLidas: true);

    expect(provider.naoLidas, 0);
  });

  test(
    'não volta a subir com as já vistas quando o provider notifica de novo',
    () async {
      repo.servidor = [_notif('a', lida: false)];
      await notificacoesProvider.carregar(marcarComoLidas: true);
      expect(provider.naoLidas, 0);

      // Filtro e swipe notificam o provider; a contagem tem que ficar em 0.
      notificacoesProvider.setFiltro(TipoNotificacao.curtida);
      notificacoesProvider.setFiltro(null);

      expect(provider.naoLidas, 0);
    },
  );

  test('não notifica quando a contagem não muda', () async {
    repo.servidor = [_notif('a', lida: false)];
    await notificacoesProvider.carregar();
    expect(notificacoes, 1);

    // Lista muda, contagem não.
    notificacoesProvider.setFiltro(TipoNotificacao.seguindo);
    realtime.emitir('nova_notificacao', _payload('a'));

    expect(provider.naoLidas, 1);
    expect(notificacoes, 1);
  });

  test('desce quando uma não lida é apagada', () async {
    repo.servidor = [_notif('a', lida: false), _notif('b', lida: false)];
    await notificacoesProvider.carregar();

    notificacoesProvider.removerLocal('a');

    expect(provider.naoLidas, 1);
  });

  test('zerar coloca em 0 e notifica se estava diferente', () async {
    repo.servidor = [_notif('a', lida: false)];
    await notificacoesProvider.carregar();
    expect(provider.naoLidas, 1);

    provider.zerar();

    expect(provider.naoLidas, 0);
    expect(notificacoes, 2);
  });

  test('zerar não notifica se já era 0', () {
    provider.zerar();

    expect(notificacoes, 0);
  });

  test('resetar zera sem depender do provider', () async {
    repo.servidor = [_notif('a', lida: false)];
    await notificacoesProvider.carregar();

    provider.resetar();

    expect(provider.naoLidas, 0);
    expect(notificacoesProvider.notificacoes, hasLength(1));
  });

  test('dispose para de escutar o provider', () async {
    provider.dispose();
    repo.servidor = [_notif('a', lida: false)];

    // Se ainda escutasse, notificaria um ChangeNotifier descartado e lançaria.
    await notificacoesProvider.carregar();
  });
}
