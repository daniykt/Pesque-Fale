import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/chat_socket_service.dart';
import '../domain/mensagem.dart';

enum StatusChat { conectando, conectado, semMutualFollow, erroConexao }

const _mensagemErroMutualFollow =
    'Vocês precisam se seguir mutuamente para conversar.';

class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required this.socketService,
    required this.usuarioLogadoId,
    required this.outroId,
  });

  final ChatSocketService socketService;
  final String usuarioLogadoId;
  final String outroId;

  StatusChat status = StatusChat.conectando;
  List<Mensagem> mensagens = [];
  bool outroDigitando = false;
  String? chatId;

  Timer? _debounceDigitando;
  Timer? _timerParouDigitando;
  bool _emitiuDigitando = false;

  /// Inicia a conexão e registra os handlers dos eventos do gateway.
  void iniciar() {
    socketService.connect();
    _registrarHandlers();
    socketService.on('connect', (_) {
      socketService.emit('entrar_chat', {'outroId': outroId});
    });
  }

  void _registrarHandlers() {
    socketService.on('historico', (data) {
      final map = data as Map<String, dynamic>;
      chatId = map['chatId'] as String;
      mensagens = (map['mensagens'] as List)
          .map((e) => Mensagem.fromJson(e as Map<String, dynamic>))
          .toList();
      status = StatusChat.conectado;
      notifyListeners();
    });

    socketService.on('nova_mensagem', (data) {
      final msg = Mensagem.fromJson(data as Map<String, dynamic>);
      mensagens.add(msg);
      // Mensagem recebida do outro enquanto a tela está visível: marca vista.
      if (msg.userId != usuarioLogadoId) {
        socketService.emit('marcar_visto');
      }
      notifyListeners();
    });

    socketService.on('mensagens_vistas', (data) {
      final map = data as Map<String, dynamic>;
      final porId = map['porId'] as String;
      // Só atualiza as PRÓPRIAS mensagens quando foi o outro quem as marcou.
      if (porId == usuarioLogadoId) return;

      for (var i = 0; i < mensagens.length; i++) {
        final m = mensagens[i];
        if (m.userId == usuarioLogadoId && m.status == StatusMensagem.enviado) {
          mensagens[i] = m.copyWith(status: StatusMensagem.visto);
        }
      }
      notifyListeners();
    });

    socketService.on('outro_digitando', (data) {
      final map = data as Map<String, dynamic>;
      if (map['userId'] == outroId) {
        outroDigitando = true;
        notifyListeners();
      }
    });

    socketService.on('outro_parou_digitando', (data) {
      final map = data as Map<String, dynamic>;
      if (map['userId'] == outroId) {
        outroDigitando = false;
        notifyListeners();
      }
    });

    socketService.on('erro', (data) {
      final map = data as Map<String, dynamic>;
      final msg = map['message'] as String? ?? '';
      status = msg == _mensagemErroMutualFollow
          ? StatusChat.semMutualFollow
          : StatusChat.erroConexao;
      notifyListeners();
    });

    // A reconexão automática do socket_io_client cuida de reabrir a conexão;
    // o 'connect' registrado em iniciar() reemite 'entrar_chat' quando reconectar.
    socketService.on('disconnect', (_) {
      if (status == StatusChat.conectado) {
        status = StatusChat.erroConexao;
        notifyListeners();
      }
    });

    socketService.on('connect_error', (_) {
      status = StatusChat.erroConexao;
      notifyListeners();
    });
  }

  void enviarMensagem(String texto) {
    final trimmed = texto.trim();
    if (trimmed.isEmpty || trimmed.length > 500) return;
    socketService.emit('enviar_mensagem', {'texto': trimmed});
    _emitirParouDigitando();
  }

  /// Chamado a cada onChanged do TextField de mensagem.
  void notificarDigitando(String texto) {
    if (texto.isEmpty) {
      _emitirParouDigitando();
      return;
    }

    // Debounce de borda de subida: agenda o emit uma única vez, sem adiar a
    // cada nova tecla — senão uma digitação contínua nunca dispararia.
    if (!_emitiuDigitando && _debounceDigitando == null) {
      _debounceDigitando = Timer(const Duration(milliseconds: 300), () {
        socketService.emit('digitando');
        _emitiuDigitando = true;
        _debounceDigitando = null;
      });
    }

    _timerParouDigitando?.cancel();
    _timerParouDigitando = Timer(
      const Duration(seconds: 3),
      _emitirParouDigitando,
    );
  }

  void _emitirParouDigitando() {
    _debounceDigitando?.cancel();
    _debounceDigitando = null;
    _timerParouDigitando?.cancel();
    _timerParouDigitando = null;
    if (_emitiuDigitando) {
      socketService.emit('parou_digitando');
      _emitiuDigitando = false;
    }
  }

  /// Chamado quando o app volta pro foreground com a tela de chat visível.
  void marcarVistoManual() {
    socketService.emit('marcar_visto');
  }

  @override
  void dispose() {
    _debounceDigitando?.cancel();
    _timerParouDigitando?.cancel();
    if (_emitiuDigitando) socketService.emit('parou_digitando');
    socketService.dispose();
    super.dispose();
  }
}
