import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/chat/domain/mensagem.dart';
import 'package:pesque_fale_app/features/chat/providers/chat_provider.dart';

import '../support/fake_realtime_manager.dart';

const _chatId = 'eu_outro';

const _eventosAssinados = [
  'historico',
  'nova_mensagem',
  'mensagens_vistas',
  'outro_digitando',
  'outro_parou_digitando',
  'erro',
];

Map<String, dynamic> _mensagemJson({
  required String id,
  required String userId,
  required String texto,
  String chatId = _chatId,
  String status = 'enviado',
}) => {
  'id': id,
  'chatId': chatId,
  'userId': userId,
  'nome': 'Fulano',
  'texto': texto,
  'status': status,
  'criadoEm': '2026-05-28T09:50:00Z',
};

Map<String, dynamic> _historico([List<Map<String, dynamic>> mensagens = const []]) =>
    {'chatId': _chatId, 'mensagens': mensagens};

void main() {
  late FakeRealtimeManager realtime;
  late ChatProvider provider;

  ChatProvider criar({bool conectado = true}) {
    realtime = FakeRealtimeManager(conectado: conectado);
    return ChatProvider(
      realtime: realtime,
      usuarioLogadoId: 'eu',
      outroId: 'outro',
    );
  }

  setUp(() => provider = criar());

  group('conexão', () {
    test('iniciar registra os 6 handlers e o listener de conexão', () {
      provider.iniciar();

      for (final evento in _eventosAssinados) {
        expect(realtime.assinantes[evento], hasLength(1), reason: evento);
      }
      expect(realtime.temOuvintes, isTrue);
    });

    test('com o manager já conectado, iniciar entra no chat na hora', () {
      provider.iniciar();

      expect(realtime.emitidos.map((e) => e.key), ['entrar_chat']);
      expect(realtime.emitidos.single.value, {'outroId': 'outro'});
    });

    test('desconectado, iniciar não emite; entra quando o manager conecta', () {
      provider = criar(conectado: false);
      provider.iniciar();
      expect(realtime.emitidos, isEmpty);

      realtime.definirConectado(true);

      expect(realtime.emitidos.map((e) => e.key), ['entrar_chat']);
    });

    test('queda muda pra erroConexao; reconexão reemite entrar_chat', () {
      provider.iniciar();
      realtime.emitir('historico', _historico());
      expect(provider.status, StatusChat.conectado);

      realtime.definirConectado(false);
      expect(provider.status, StatusChat.erroConexao);

      realtime.definirConectado(true);
      expect(
        realtime.emitidos.where((e) => e.key == 'entrar_chat'),
        hasLength(2),
      );

      realtime.emitir('historico', _historico());
      expect(provider.status, StatusChat.conectado);
    });

    test('queda antes do histórico não muda o status', () {
      provider.iniciar();

      realtime.definirConectado(false);

      expect(provider.status, StatusChat.conectando);
    });

    test('dispose desinscreve os handlers, remove o listener e não '
        'descarta o manager', () {
      provider.iniciar();

      provider.dispose();

      for (final evento in _eventosAssinados) {
        expect(realtime.assinantes[evento], isEmpty, reason: evento);
      }
      expect(realtime.temOuvintes, isFalse);
      // Manager global continua utilizável depois.
      expect(() => realtime.definirConectado(false), returnsNormally);
    });
  });

  group('historico', () {
    test('popula mensagens e muda status para conectado', () {
      provider.iniciar();

      realtime.emitir(
        'historico',
        _historico([_mensagemJson(id: 'm1', userId: 'eu', texto: 'oi')]),
      );

      expect(provider.status, StatusChat.conectado);
      expect(provider.chatId, _chatId);
      expect(provider.mensagens, hasLength(1));
    });

    test('de uma conversa sem este participante é ignorado', () {
      provider.iniciar();

      realtime.emitir('historico', {'chatId': 'eu_terceiro', 'mensagens': []});

      expect(provider.status, StatusChat.conectando);
      expect(provider.chatId, isNull);
    });
  });

  group('nova_mensagem', () {
    setUp(() {
      provider.iniciar();
      realtime.emitir('historico', _historico());
      realtime.emitidos.clear();
    });

    test('do outro adiciona e marca como vista', () {
      realtime.emitir(
        'nova_mensagem',
        _mensagemJson(id: 'm1', userId: 'outro', texto: 'oi'),
      );

      expect(provider.mensagens, hasLength(1));
      expect(realtime.foiEmitido('marcar_visto'), isTrue);
    });

    test('própria não emite marcar_visto', () {
      realtime.emitir(
        'nova_mensagem',
        _mensagemJson(id: 'm1', userId: 'eu', texto: 'oi'),
      );

      expect(provider.mensagens, hasLength(1));
      expect(realtime.foiEmitido('marcar_visto'), isFalse);
    });

    test('de outro chat é ignorada', () {
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      realtime.emitir(
        'nova_mensagem',
        _mensagemJson(
          id: 'm1',
          userId: 'terceiro',
          texto: 'oi',
          chatId: 'eu_terceiro',
        ),
      );

      expect(provider.mensagens, isEmpty);
      expect(realtime.foiEmitido('marcar_visto'), isFalse);
      expect(notificacoes, 0);
    });
  });

  group('mensagens_vistas', () {
    setUp(() {
      provider.iniciar();
      realtime.emitir(
        'historico',
        _historico([
          _mensagemJson(id: 'm1', userId: 'eu', texto: 'oi'),
          _mensagemJson(id: 'm2', userId: 'outro', texto: 'oi de volta'),
        ]),
      );
    });

    test('do outro atualiza status das próprias mensagens', () {
      realtime.emitir('mensagens_vistas', {
        'chatId': _chatId,
        'porId': 'outro',
      });

      expect(provider.mensagens[0].status, StatusMensagem.visto);
      expect(provider.mensagens[1].status, StatusMensagem.enviado);
    });

    test('emitido por mim mesmo não altera nada', () {
      realtime.emitir('mensagens_vistas', {'chatId': _chatId, 'porId': 'eu'});

      expect(provider.mensagens[0].status, StatusMensagem.enviado);
    });

    test('de outro chat é ignorado', () {
      realtime.emitir('mensagens_vistas', {
        'chatId': 'eu_terceiro',
        'porId': 'terceiro',
      });

      expect(provider.mensagens[0].status, StatusMensagem.enviado);
    });
  });

  group('erro', () {
    test('de mutual follow define status semMutualFollow', () {
      provider.iniciar();

      realtime.emitir('erro', {
        'message': 'Vocês precisam se seguir mutuamente para conversar.',
      });

      expect(provider.status, StatusChat.semMutualFollow);
    });

    test('genérico define status erroConexao', () {
      provider.iniciar();

      realtime.emitir('erro', {'message': 'Erro ao enviar mensagem.'});

      expect(provider.status, StatusChat.erroConexao);
    });
  });

  group('digitando', () {
    test('outro_digitando e outro_parou_digitando alternam a flag', () {
      provider.iniciar();

      realtime.emitir('outro_digitando', {'userId': 'outro'});
      expect(provider.outroDigitando, isTrue);

      realtime.emitir('outro_parou_digitando', {'userId': 'outro'});
      expect(provider.outroDigitando, isFalse);
    });

    test('outro_digitando de outro userId é ignorado', () {
      provider.iniciar();

      realtime.emitir('outro_digitando', {'userId': 'terceiro'});

      expect(provider.outroDigitando, isFalse);
    });

    test(
      'notificarDigitando emite digitando após 300ms mesmo com digitação contínua',
      () async {
        provider.notificarDigitando('o');
        provider.notificarDigitando('oi');
        provider.notificarDigitando('oi t');

        expect(realtime.foiEmitido('digitando'), isFalse);

        await Future.delayed(const Duration(milliseconds: 350));

        expect(
          realtime.emitidos.where((e) => e.key == 'digitando'),
          hasLength(1),
        );
      },
    );

    test('notificarDigitando com texto vazio emite parou_digitando', () async {
      provider.notificarDigitando('o');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(realtime.foiEmitido('digitando'), isTrue);

      provider.notificarDigitando('');

      expect(realtime.foiEmitido('parou_digitando'), isTrue);
    });

    test('dispose emite parou_digitando se estava digitando', () async {
      provider.iniciar();
      provider.notificarDigitando('oi');
      await Future.delayed(const Duration(milliseconds: 350));

      provider.dispose();

      expect(realtime.foiEmitido('parou_digitando'), isTrue);
    });
  });

  group('enviarMensagem', () {
    test('emite enviar_mensagem com texto trimado', () {
      provider.enviarMensagem('  oi tudo bem  ');

      final emitido = realtime.emitidos.firstWhere(
        (e) => e.key == 'enviar_mensagem',
      );
      expect(emitido.value, {'texto': 'oi tudo bem'});
    });

    test('ignora texto vazio', () {
      provider.enviarMensagem('   ');
      expect(realtime.foiEmitido('enviar_mensagem'), isFalse);
    });

    test('ignora texto acima de 500 caracteres', () {
      provider.enviarMensagem('a' * 501);
      expect(realtime.foiEmitido('enviar_mensagem'), isFalse);
    });

    test('emite parou_digitando se estava digitando', () async {
      provider.notificarDigitando('oi');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(realtime.foiEmitido('digitando'), isTrue);

      provider.enviarMensagem('oi');

      expect(realtime.foiEmitido('parou_digitando'), isTrue);
    });
  });

  test('marcarVistoManual emite marcar_visto', () {
    provider.marcarVistoManual();

    expect(realtime.emitidos.map((e) => e.key), ['marcar_visto']);
  });
}
