import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/chat/data/conversas_repository.dart';
import 'package:pesque_fale_app/features/chat/domain/conversa.dart';
import 'package:pesque_fale_app/features/chat/providers/badge_mensagens_provider.dart';
import 'package:pesque_fale_app/features/chat/providers/inbox_provider.dart';

import '../support/fake_realtime_manager.dart';

Conversa _conv(String id, {required int naoLidas}) => Conversa(
  id: id,
  outroId: 'u-$id',
  outroNome: 'User $id',
  outroUsername: 'user_$id',
  outroFoto: null,
  ultimaMensagem: 'oi',
  ultimaMensagemEm: DateTime.utc(2026, 10, 1),
  naoLidas: naoLidas,
  criadoEm: DateTime(2026, 9, 1),
);

Map<String, dynamic> _preview(String conversaId) => {
  'conversaId': conversaId,
  'previewTexto': 'nova',
  'timestamp': '2026-10-27T13:00:00.000Z',
  'remetenteId': 'u-$conversaId',
};

class _FakeConversasRepository implements ConversasRepository {
  List<Conversa> conversas = const [];

  @override
  Future<List<Conversa>> listar() async => conversas;
}

void main() {
  late _FakeConversasRepository repo;
  late FakeRealtimeManager realtime;
  late InboxProvider inbox;
  late BadgeMensagensProvider provider;
  late int notificacoes;

  setUp(() {
    repo = _FakeConversasRepository();
    realtime = FakeRealtimeManager();
    inbox = InboxProvider(repository: repo, realtime: realtime);
    provider = BadgeMensagensProvider(inbox: inbox);
    notificacoes = 0;
    provider.addListener(() => notificacoes++);
  });

  test(
    'conta conversas com nao-lidas > 0 quando a lista do inbox carrega',
    () async {
      repo.conversas = [
        _conv('a', naoLidas: 3),
        _conv('b', naoLidas: 0),
        _conv('c', naoLidas: 1),
      ];

      await inbox.carregar();

      // 2 conversas com não-lidas, não 4 mensagens.
      expect(provider.naoLidas, 2);
      expect(notificacoes, 1);
    },
  );

  test('ja nasce com a contagem do inbox', () async {
    repo.conversas = [_conv('a', naoLidas: 1)];
    await inbox.carregar();

    final outro = BadgeMensagensProvider(inbox: inbox);

    expect(outro.naoLidas, 1);
  });

  test('recalcula quando um evento realtime muda a lista do inbox', () async {
    repo.conversas = [_conv('a', naoLidas: 0), _conv('b', naoLidas: 0)];
    await inbox.carregar();
    expect(provider.naoLidas, 0);

    realtime.emitir('nova_mensagem_em_conversa', _preview('a'));
    expect(provider.naoLidas, 1);

    realtime.emitir('nova_mensagem_em_conversa', _preview('b'));
    expect(provider.naoLidas, 2);
  });

  test('nao notifica quando a contagem nao muda', () async {
    repo.conversas = [_conv('a', naoLidas: 2)];
    await inbox.carregar();
    expect(notificacoes, 1);

    // Mais uma não-lida na mesma conversa: lista muda, contagem não.
    realtime.emitir('nova_mensagem_em_conversa', _preview('a'));
    inbox.setTermoBusca('user');

    expect(provider.naoLidas, 1);
    expect(notificacoes, 1);
  });

  test('zerar coloca em 0 e notifica se estava diferente', () async {
    repo.conversas = [_conv('a', naoLidas: 1)];
    await inbox.carregar();
    expect(provider.naoLidas, 1);

    provider.zerar();

    expect(provider.naoLidas, 0);
    expect(notificacoes, 2);
  });

  test('zerar nao notifica se ja era 0', () {
    provider.zerar();

    expect(notificacoes, 0);
  });

  test('resetar zera sem depender do inbox', () async {
    repo.conversas = [_conv('a', naoLidas: 1)];
    await inbox.carregar();

    provider.resetar();

    expect(provider.naoLidas, 0);
    expect(inbox.conversasInternas, hasLength(1));
  });

  test('dispose para de escutar o inbox', () async {
    provider.dispose();
    repo.conversas = [_conv('a', naoLidas: 1)];

    // Se ainda escutasse, notificaria um ChangeNotifier descartado e lançaria.
    await inbox.carregar();
  });
}
