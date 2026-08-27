import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/chat/data/chat_socket_service.dart';
import 'package:pesque_fale_app/features/chat/domain/mensagem.dart';
import 'package:pesque_fale_app/features/chat/providers/chat_provider.dart';

class _FakeChatSocketService extends ChatSocketService {
  _FakeChatSocketService() : super(token: 'fake-token');

  final Map<String, void Function(dynamic)> handlers = {};
  final List<MapEntry<String, dynamic>> emitidos = [];
  bool conectarChamado = false;
  bool disposeChamado = false;

  @override
  void connect() => conectarChamado = true;

  @override
  void on(String evento, void Function(dynamic) callback) {
    handlers[evento] = callback;
  }

  @override
  void off(String evento) => handlers.remove(evento);

  @override
  void emit(String evento, [dynamic dados]) {
    emitidos.add(MapEntry(evento, dados));
  }

  @override
  void dispose() => disposeChamado = true;

  void simular(String evento, dynamic dados) => handlers[evento]?.call(dados);

  bool foiEmitido(String evento) => emitidos.any((e) => e.key == evento);
}

Map<String, dynamic> _mensagemJson({
  required String id,
  required String userId,
  required String texto,
  String status = 'enviado',
}) => {
  'id': id,
  'chatId': 'u1_u2',
  'userId': userId,
  'nome': 'Fulano',
  'texto': texto,
  'status': status,
  'criadoEm': '2026-05-28T09:50:00Z',
};

void main() {
  late _FakeChatSocketService socket;
  late ChatProvider provider;

  setUp(() {
    socket = _FakeChatSocketService();
    provider = ChatProvider(
      socketService: socket,
      usuarioLogadoId: 'eu',
      outroId: 'outro',
    );
  });

  test('iniciar conecta e entra no chat ao receber connect', () {
    provider.iniciar();
    expect(socket.conectarChamado, isTrue);

    socket.simular('connect', null);

    expect(socket.foiEmitido('entrar_chat'), isTrue);
    final emitido = socket.emitidos.firstWhere((e) => e.key == 'entrar_chat');
    expect(emitido.value, {'outroId': 'outro'});
  });

  test('historico popula mensagens e muda status para conectado', () {
    provider.iniciar();

    socket.simular('historico', {
      'chatId': 'u1_u2',
      'mensagens': [
        _mensagemJson(id: 'm1', userId: 'eu', texto: 'oi'),
      ],
    });

    expect(provider.status, StatusChat.conectado);
    expect(provider.chatId, 'u1_u2');
    expect(provider.mensagens, hasLength(1));
  });

  test('nova_mensagem do outro adiciona e marca como vista', () {
    provider.iniciar();

    socket.simular(
      'nova_mensagem',
      _mensagemJson(id: 'm1', userId: 'outro', texto: 'oi'),
    );

    expect(provider.mensagens, hasLength(1));
    expect(socket.foiEmitido('marcar_visto'), isTrue);
  });

  test('nova_mensagem propria nao emite marcar_visto', () {
    provider.iniciar();

    socket.simular(
      'nova_mensagem',
      _mensagemJson(id: 'm1', userId: 'eu', texto: 'oi'),
    );

    expect(provider.mensagens, hasLength(1));
    expect(socket.foiEmitido('marcar_visto'), isFalse);
  });

  test('mensagens_vistas do outro atualiza status das proprias mensagens', () {
    provider.iniciar();
    socket.simular('historico', {
      'chatId': 'u1_u2',
      'mensagens': [
        _mensagemJson(id: 'm1', userId: 'eu', texto: 'oi'),
        _mensagemJson(id: 'm2', userId: 'outro', texto: 'oi de volta'),
      ],
    });

    socket.simular('mensagens_vistas', {'chatId': 'u1_u2', 'porId': 'outro'});

    expect(provider.mensagens[0].status, StatusMensagem.visto);
    expect(provider.mensagens[1].status, StatusMensagem.enviado);
  });

  test('mensagens_vistas emitido por mim mesmo nao altera nada', () {
    provider.iniciar();
    socket.simular('historico', {
      'chatId': 'u1_u2',
      'mensagens': [_mensagemJson(id: 'm1', userId: 'eu', texto: 'oi')],
    });

    socket.simular('mensagens_vistas', {'chatId': 'u1_u2', 'porId': 'eu'});

    expect(provider.mensagens[0].status, StatusMensagem.enviado);
  });

  test('erro de mutual follow define status semMutualFollow', () {
    provider.iniciar();

    socket.simular('erro', {
      'message': 'Vocês precisam se seguir mutuamente para conversar.',
    });

    expect(provider.status, StatusChat.semMutualFollow);
  });

  test('erro generico define status erroConexao', () {
    provider.iniciar();

    socket.simular('erro', {'message': 'Erro ao enviar mensagem.'});

    expect(provider.status, StatusChat.erroConexao);
  });

  test('outro_digitando e outro_parou_digitando alternam a flag', () {
    provider.iniciar();

    socket.simular('outro_digitando', {'userId': 'outro'});
    expect(provider.outroDigitando, isTrue);

    socket.simular('outro_parou_digitando', {'userId': 'outro'});
    expect(provider.outroDigitando, isFalse);
  });

  test('outro_digitando de outro userId e ignorado', () {
    provider.iniciar();

    socket.simular('outro_digitando', {'userId': 'terceiro'});

    expect(provider.outroDigitando, isFalse);
  });

  test('enviarMensagem emite enviar_mensagem com texto trimado', () {
    provider.enviarMensagem('  oi tudo bem  ');

    expect(socket.foiEmitido('enviar_mensagem'), isTrue);
    final emitido = socket.emitidos.firstWhere(
      (e) => e.key == 'enviar_mensagem',
    );
    expect(emitido.value, {'texto': 'oi tudo bem'});
  });

  test('enviarMensagem ignora texto vazio', () {
    provider.enviarMensagem('   ');
    expect(socket.foiEmitido('enviar_mensagem'), isFalse);
  });

  test('enviarMensagem ignora texto acima de 500 caracteres', () {
    provider.enviarMensagem('a' * 501);
    expect(socket.foiEmitido('enviar_mensagem'), isFalse);
  });

  test(
    'notificarDigitando emite digitando apos 300ms mesmo com digitacao continua',
    () async {
      provider.notificarDigitando('o');
      provider.notificarDigitando('oi');
      provider.notificarDigitando('oi t');

      expect(socket.foiEmitido('digitando'), isFalse);

      await Future.delayed(const Duration(milliseconds: 350));

      expect(
        socket.emitidos.where((e) => e.key == 'digitando'),
        hasLength(1),
      );
    },
  );

  test('notificarDigitando com texto vazio emite parou_digitando', () async {
    provider.notificarDigitando('o');
    await Future.delayed(const Duration(milliseconds: 350));
    expect(socket.foiEmitido('digitando'), isTrue);

    provider.notificarDigitando('');

    expect(socket.foiEmitido('parou_digitando'), isTrue);
  });

  test('enviarMensagem emite parou_digitando se estava digitando', () async {
    provider.notificarDigitando('oi');
    await Future.delayed(const Duration(milliseconds: 350));
    expect(socket.foiEmitido('digitando'), isTrue);

    provider.enviarMensagem('oi');

    expect(socket.foiEmitido('parou_digitando'), isTrue);
  });

  test('dispose limpa timers e fecha o socket', () {
    provider.dispose();
    expect(socket.disposeChamado, isTrue);
  });
}
