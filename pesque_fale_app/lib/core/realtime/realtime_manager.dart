import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../features/auth/providers/auth_provider.dart';
import '../config/app_config.dart';

typedef CriarSocket = io.Socket Function(String token);

/// Dono da única conexão Socket.IO do usuário logado.
///
/// Conecta quando o [AuthProvider] passa a ter sessão e desconecta no logout,
/// via [reagirAuth]. O backend coloca esse socket no room `user:<id>`, então
/// o que for emitido pra esse usuário chega em todos os dispositivos logados.
///
/// Assinaturas feitas com [subscribe] e [onReconnect] ficam guardadas aqui e
/// são reaplicadas em cada socket novo — sobrevivem a quedas, logout e troca
/// de conta. No logout só o socket (e os handlers registrados nele) é
/// descartado. Assim, providers globais (ex.: badges) assinam uma vez só.
///
/// **Contrato pros assinantes:** como a mesma assinatura atravessa sessões
/// de contas diferentes, os callbacks passados pra [subscribe] e
/// [onReconnect] NÃO podem capturar no closure dados do usuário logado
/// (`userId`, nome etc.). Eles devem reagir ao payload do evento recebido
/// do backend, ou ler o estado do [AuthProvider] no momento em que rodam.
/// Quem tem ciclo de vida menor que o app (ex.: provider criado por rota)
/// deve desfazer as assinaturas no próprio `dispose` com [unsubscribe] e
/// [removerOnReconnect].
class RealtimeManager extends ChangeNotifier {
  RealtimeManager({CriarSocket? criarSocket})
    : _criarSocket = criarSocket ?? _socketPadrao;

  final CriarSocket _criarSocket;
  final Map<String, List<void Function(dynamic)>> _assinantes = {};
  final List<void Function()> _callbacksReconexao = [];

  io.Socket? _socket;
  String? _token;
  bool _conectado = false;
  bool _jaConectou = false;
  bool _descartado = false;

  bool get conectado => _conectado;

  static io.Socket _socketPadrao(String token) => io.io(
    // O gateway de Socket.IO roda na raiz do servidor HTTP, não sob /v1.
    AppConfig.apiBaseUrl.replaceFirst('/v1', ''),
    // A unicidade da conexão vem do manager (um socket por sessão), não do
    // cache do socket_io_client. Sem enableForceNew() a lib (3.1.6) devolve o
    // socket antigo do cache — com o auth da sessão anterior — e um logout
    // seguido de login com outra conta reconectaria com o token velho.
    io.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .enableForceNew()
        .disableAutoConnect()
        .enableReconnection()
        .setReconnectionDelay(2000)
        .build(),
  );

  /// Chamado pelo `ChangeNotifierProxyProvider` a cada mudança no auth.
  void reagirAuth(AuthProvider auth) {
    final token = auth.token;
    if (auth.estaLogado && token != null && token.isNotEmpty) {
      _conectar(token);
    } else {
      _desconectar();
    }
  }

  void subscribe(String evento, void Function(dynamic) callback) {
    _assinantes.putIfAbsent(evento, () => []).add(callback);
    _socket?.on(evento, callback);
  }

  void unsubscribe(String evento, void Function(dynamic) callback) {
    final callbacks = _assinantes[evento];
    callbacks?.remove(callback);
    if (callbacks != null && callbacks.isEmpty) _assinantes.remove(evento);
    _socket?.off(evento, callback);
  }

  /// [callback] roda quando o socket volta depois de uma queda — não na
  /// primeira conexão da sessão. É o gancho pra re-sincronizar estado.
  void onReconnect(void Function() callback) {
    _callbacksReconexao.add(callback);
  }

  /// Remove um callback previamente registrado via [onReconnect].
  /// A comparação é por identidade de referência da função.
  /// Chamadas com um callback que não está registrado são no-op.
  void removerOnReconnect(void Function() callback) {
    _callbacksReconexao.remove(callback);
  }

  void _conectar(String token) {
    if (_socket != null && token == _token) return;
    _desconectar(); // token diferente = outra sessão; não reaproveita socket.

    _token = token;
    final socket = _criarSocket(token);
    socket.on('connect', (_) {
      final reconexao = _jaConectou;
      _jaConectou = true;
      _setConectado(true);
      if (reconexao) {
        for (final callback in List.of(_callbacksReconexao)) {
          callback();
        }
      }
    });
    socket.on('disconnect', (_) => _setConectado(false));
    _assinantes.forEach((evento, callbacks) {
      for (final callback in callbacks) {
        socket.on(evento, callback);
      }
    });
    _socket = socket;
    socket.connect();
  }

  void _desconectar() {
    final socket = _socket;
    if (socket == null) return;
    _socket = null;
    _token = null;
    _jaConectou = false;
    socket.dispose();
    _setConectado(false);
  }

  void _setConectado(bool valor) {
    if (_conectado == valor || _descartado) return;
    _conectado = valor;
    notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _desconectar();
    _assinantes.clear();
    _callbacksReconexao.clear();
    super.dispose();
  }
}
