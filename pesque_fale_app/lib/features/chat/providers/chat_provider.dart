import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/realtime/realtime_manager.dart';
import '../domain/mensagem.dart';

enum StatusChat { conectando, conectado, semMutualFollow, erroConexao }

const _mensagemErroMutualFollow =
    'Vocês precisam se seguir mutuamente para conversar.';

/// Estado de uma conversa aberta. Vive enquanto a tela de chat existe e
/// conversa com o backend pelo socket global do [RealtimeManager].
///
/// O socket global continua nos rooms de conversas abertas antes (o backend
/// não tem `sair_chat`), então eventos de room de outros chats também chegam
/// aqui: os handlers filtram pelo `chatId` desta conversa.
class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required this.realtime,
    required this.usuarioLogadoId,
    required this.outroId,
  });

  final RealtimeManager realtime;
  final String usuarioLogadoId;
  final String outroId;

  StatusChat status = StatusChat.conectando;
  List<Mensagem> mensagens = [];
  bool outroDigitando = false;
  String? chatId;

  /// Id desta conversa, conhecido a partir do `historico`. Antes disso o
  /// filtro dos handlers é permissivo e os emits que dependem da conversa
  /// (que levam o `chatId` pro backend validar) são descartados. É campo da
  /// instância, não closure —
  /// mesmo contrato stateless do `_meuId` no `InboxProvider`.
  String? _chatIdAtivo;

  Timer? _debounceDigitando;
  Timer? _timerParouDigitando;
  bool _emitiuDigitando = false;

  /// Registra os handlers no manager e entra no chat assim que houver
  /// conexão (agora, se já conectado, ou no próximo `conectado == true`).
  void iniciar() {
    realtime.subscribe('historico', _onHistorico);
    realtime.subscribe('nova_mensagem', _onNovaMensagem);
    realtime.subscribe('mensagens_vistas', _onMensagensVistas);
    realtime.subscribe('outro_digitando', _onOutroDigitando);
    realtime.subscribe('outro_parou_digitando', _onOutroParouDigitando);
    realtime.subscribe('erro', _onErro);
    realtime.addListener(_onConexaoMudou);
    if (realtime.conectado) _entrarChat();
  }

  void _entrarChat() => realtime.emit('entrar_chat', {'outroId': outroId});

  /// O manager só notifica quando `conectado` muda. Conectar — pela primeira
  /// vez ou depois de uma queda — reemite `entrar_chat`, que devolve o
  /// histórico atualizado. O backend é idempotente, então um `entrar_chat`
  /// duplicado por corrida com o [iniciar] é inofensivo.
  void _onConexaoMudou() {
    if (realtime.conectado) {
      _entrarChat();
    } else if (status == StatusChat.conectado) {
      status = StatusChat.erroConexao;
      notifyListeners();
    }
  }

  /// `true` se o evento é de outra conversa e deve ser descartado.
  bool _deOutroChat(Map data) =>
      _chatIdAtivo != null && data['chatId'] != _chatIdAtivo;

  void _onHistorico(dynamic data) {
    if (data is! Map) return;
    final id = data['chatId'] as String;
    // Resposta atrasada de um `entrar_chat` de outra tela (ex.: abriu e
    // fechou outra conversa logo antes): o chatId não tem este participante.
    if (!id.split('_').contains(outroId)) return;
    chatId = id;
    _chatIdAtivo = id;
    mensagens = (data['mensagens'] as List)
        .map((e) => Mensagem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    status = StatusChat.conectado;
    notifyListeners();
  }

  void _onNovaMensagem(dynamic data) {
    if (data is! Map || _deOutroChat(data)) return;
    final msg = Mensagem.fromJson(Map<String, dynamic>.from(data));
    mensagens.add(msg);
    // Mensagem recebida do outro enquanto a tela está visível: marca vista.
    if (msg.userId != usuarioLogadoId && _chatIdAtivo != null) {
      realtime.emit('marcar_visto', {'chatId': _chatIdAtivo});
    }
    notifyListeners();
  }

  void _onMensagensVistas(dynamic data) {
    if (data is! Map || _deOutroChat(data)) return;
    final porId = data['porId'] as String;
    // Só atualiza as PRÓPRIAS mensagens quando foi o outro quem as marcou.
    if (porId == usuarioLogadoId) return;

    for (var i = 0; i < mensagens.length; i++) {
      final m = mensagens[i];
      if (m.userId == usuarioLogadoId && m.status == StatusMensagem.enviado) {
        mensagens[i] = m.copyWith(status: StatusMensagem.visto);
      }
    }
    notifyListeners();
  }

  // `outro_digitando` / `outro_parou_digitando` não trazem `chatId`: o backend
  // emite só no room do chat. Se o socket ainda estiver no room de uma
  // conversa anterior, o filtro por `userId == outroId` descarta o evento.

  void _onOutroDigitando(dynamic data) {
    if (data is! Map || data['userId'] != outroId) return;
    outroDigitando = true;
    notifyListeners();
  }

  void _onOutroParouDigitando(dynamic data) {
    if (data is! Map || data['userId'] != outroId) return;
    outroDigitando = false;
    notifyListeners();
  }

  void _onErro(dynamic data) {
    if (data is! Map) return;
    final code = data['code'] as String?;
    final msg = data['message'] as String? ?? '';

    if (code == 'CHAT_FORA_DE_SINCRONIA') {
      // Backend está num chat diferente do nosso. Mostra "sincronizando"
      // (reaproveitando o visual de reconexão) e desabilita envios até o
      // próximo historico chegar com _chatIdAtivo correto.
      if (status == StatusChat.conectado) {
        status = StatusChat.conectando;
        notifyListeners();
      }
      _entrarChat();
      return;
    }

    status = msg == _mensagemErroMutualFollow
        ? StatusChat.semMutualFollow
        : StatusChat.erroConexao;
    notifyListeners();
  }

  void enviarMensagem(String texto) {
    final trimmed = texto.trim();
    if (trimmed.isEmpty || trimmed.length > 500) return;
    // Só envia quando totalmente sincronizado. Se o botão da UI estiver
    // habilitado nessa condição, isso é defesa em profundidade.
    if (status != StatusChat.conectado || _chatIdAtivo == null) return;
    realtime.emit('enviar_mensagem', {
      'texto': trimmed,
      'chatId': _chatIdAtivo,
    });
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
        _debounceDigitando = null;
        if (_chatIdAtivo == null) return;
        realtime.emit('digitando', {'chatId': _chatIdAtivo});
        _emitiuDigitando = true;
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
    // `_emitiuDigitando` só fica true depois de um `digitando` com chatId.
    if (_emitiuDigitando) {
      realtime.emit('parou_digitando', {'chatId': _chatIdAtivo});
      _emitiuDigitando = false;
    }
  }

  /// Chamado quando o app volta pro foreground com a tela de chat visível.
  void marcarVistoManual() {
    if (_chatIdAtivo == null) return;
    realtime.emit('marcar_visto', {'chatId': _chatIdAtivo});
  }

  /// Desfaz as assinaturas no manager. Não descarta o manager: ele é global.
  @override
  void dispose() {
    _debounceDigitando?.cancel();
    _timerParouDigitando?.cancel();
    if (_emitiuDigitando && _chatIdAtivo != null) {
      realtime.emit('parou_digitando', {'chatId': _chatIdAtivo});
    }
    realtime.unsubscribe('historico', _onHistorico);
    realtime.unsubscribe('nova_mensagem', _onNovaMensagem);
    realtime.unsubscribe('mensagens_vistas', _onMensagensVistas);
    realtime.unsubscribe('outro_digitando', _onOutroDigitando);
    realtime.unsubscribe('outro_parou_digitando', _onOutroParouDigitando);
    realtime.unsubscribe('erro', _onErro);
    realtime.removeListener(_onConexaoMudou);
    super.dispose();
  }
}
