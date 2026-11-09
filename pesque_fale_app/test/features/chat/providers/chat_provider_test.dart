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

Map<String, dynamic> _historico([
  List<Map<String, dynamic>> mensagens = const [],
]) => {'chatId': _chatId, 'mensagens': mensagens};

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

  /// Inicia e recebe o `historico`: a partir daqui o provider conhece o
  /// `chatId` e os emits que dependem dele saem. Limpa o `entrar_chat`.
  void entrarNoChat() {
    provider.iniciar();
    realtime.emitir('historico', _historico());
    realtime.emitidos.clear();
  }

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
    setUp(entrarNoChat);

    test('do outro adiciona e marca como vista com o chatId', () {
      realtime.emitir(
        'nova_mensagem',
        _mensagemJson(id: 'm1', userId: 'outro', texto: 'oi'),
      );

      expect(provider.mensagens, hasLength(1));
      expect(realtime.emitidos.single.key, 'marcar_visto');
      expect(realtime.emitidos.single.value, {'chatId': _chatId});
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

    test('com outro code mantém o fluxo antigo (erroConexao)', () {
      provider.iniciar();

      realtime.emitir('erro', {
        'code': 'CHAT_CONSIGO_MESMO',
        'message': 'Não é possível conversar consigo mesmo.',
      });

      expect(provider.status, StatusChat.erroConexao);
    });

    test('CHAT_FORA_DE_SINCRONIA conectado muda pra conectando e reemite '
        'entrar_chat', () {
      entrarNoChat();
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      realtime.emitir('erro', {
        'code': 'CHAT_FORA_DE_SINCRONIA',
        'message': 'A conversa mudou. Tente novamente.',
      });

      expect(provider.status, StatusChat.conectando);
      expect(provider.chatId, _chatId);
      expect(notificacoes, 1);
      expect(realtime.emitidos.single.key, 'entrar_chat');
      expect(realtime.emitidos.single.value, {'outroId': 'outro'});
    });

    test('CHAT_FORA_DE_SINCRONIA fora de conectado não muda o status nem '
        'notifica', () {
      provider.iniciar();
      realtime.emitidos.clear();
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      realtime.emitir('erro', {'code': 'CHAT_FORA_DE_SINCRONIA'});

      expect(provider.status, StatusChat.conectando);
      expect(notificacoes, 0);
      expect(realtime.emitidos.single.key, 'entrar_chat');
    });

    test('depois do CHAT_FORA_DE_SINCRONIA, o historico seguinte volta pra '
        'conectado', () {
      entrarNoChat();
      realtime.emitir('erro', {'code': 'CHAT_FORA_DE_SINCRONIA'});

      realtime.emitir('historico', _historico());

      expect(provider.status, StatusChat.conectado);
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

    test('notificarDigitando emite digitando com chatId após 300ms mesmo com '
        'digitação contínua', () async {
      entrarNoChat();
      provider.notificarDigitando('o');
      provider.notificarDigitando('oi');
      provider.notificarDigitando('oi t');

      expect(realtime.foiEmitido('digitando'), isFalse);

      await Future.delayed(const Duration(milliseconds: 350));

      final digitando = realtime.emitidos.where((e) => e.key == 'digitando');
      expect(digitando, hasLength(1));
      expect(digitando.single.value, {'chatId': _chatId});
    });

    test('antes do historico, notificarDigitando não emite nada', () async {
      provider.iniciar();
      realtime.emitidos.clear();

      provider.notificarDigitando('oi');
      await Future.delayed(const Duration(milliseconds: 350));
      provider.notificarDigitando('');

      expect(realtime.emitidos, isEmpty);
    });

    test('notificarDigitando com texto vazio emite parou_digitando', () async {
      entrarNoChat();
      provider.notificarDigitando('o');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(realtime.foiEmitido('digitando'), isTrue);

      provider.notificarDigitando('');

      final parou = realtime.emitidos.last;
      expect(parou.key, 'parou_digitando');
      expect(parou.value, {'chatId': _chatId});
    });

    test('dispose emite parou_digitando se estava digitando', () async {
      entrarNoChat();
      provider.notificarDigitando('oi');
      await Future.delayed(const Duration(milliseconds: 350));

      provider.dispose();

      final parou = realtime.emitidos.last;
      expect(parou.key, 'parou_digitando');
      expect(parou.value, {'chatId': _chatId});
    });
  });

  group('enviarMensagem', () {
    test('antes do historico é no-op (sem chatId conhecido)', () {
      provider.iniciar();
      realtime.emitidos.clear();

      provider.enviarMensagem('oi');

      expect(realtime.emitidos, isEmpty);
    });

    test('ressincronizando (CHAT_FORA_DE_SINCRONIA) é no-op mesmo com chatId '
        'conhecido', () {
      entrarNoChat();
      realtime.emitir('erro', {'code': 'CHAT_FORA_DE_SINCRONIA'});
      realtime.emitidos.clear();

      provider.enviarMensagem('oi');

      expect(realtime.emitidos, isEmpty);
    });

    test('reconectado mas ainda em erroConexao (antes do historico) é no-op', () {
      entrarNoChat();
      realtime.definirConectado(false);
      realtime.definirConectado(true);
      expect(provider.status, StatusChat.erroConexao);
      realtime.emitidos.clear();

      provider.enviarMensagem('oi');

      expect(realtime.emitidos, isEmpty);
    });

    test('emite enviar_mensagem com texto trimado e o chatId do historico', () {
      entrarNoChat();

      provider.enviarMensagem('  oi tudo bem  ');

      expect(realtime.emitidos.single.key, 'enviar_mensagem');
      expect(realtime.emitidos.single.value, {
        'texto': 'oi tudo bem',
        'chatId': _chatId,
      });
    });

    test('ignora texto vazio', () {
      entrarNoChat();
      provider.enviarMensagem('   ');
      expect(realtime.foiEmitido('enviar_mensagem'), isFalse);
    });

    test('ignora texto acima de 500 caracteres', () {
      entrarNoChat();
      provider.enviarMensagem('a' * 501);
      expect(realtime.foiEmitido('enviar_mensagem'), isFalse);
    });

    test('emite parou_digitando se estava digitando', () async {
      entrarNoChat();
      provider.notificarDigitando('oi');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(realtime.foiEmitido('digitando'), isTrue);

      provider.enviarMensagem('oi');

      expect(realtime.foiEmitido('parou_digitando'), isTrue);
    });

    test('depois de um reemit por CHAT_FORA_DE_SINCRONIA, carrega o chatId '
        'do historico mais recente', () {
      entrarNoChat();
      realtime.emitir('erro', {'code': 'CHAT_FORA_DE_SINCRONIA'});
      // Resposta atrasada de outra conversa não troca o chatId ativo.
      realtime.emitir('historico', {'chatId': 'eu_terceiro', 'mensagens': []});
      realtime.emitir('historico', _historico());
      realtime.emitidos.clear();

      provider.enviarMensagem('oi');

      expect(realtime.emitidos.single.value, {
        'texto': 'oi',
        'chatId': _chatId,
      });
    });
  });

  group('marcarVistoManual', () {
    test('antes do historico é no-op', () {
      provider.iniciar();
      realtime.emitidos.clear();

      provider.marcarVistoManual();

      expect(realtime.emitidos, isEmpty);
    });

    test('emite marcar_visto com o chatId', () {
      entrarNoChat();

      provider.marcarVistoManual();

      expect(realtime.emitidos.single.key, 'marcar_visto');
      expect(realtime.emitidos.single.value, {'chatId': _chatId});
    });
  });
}
