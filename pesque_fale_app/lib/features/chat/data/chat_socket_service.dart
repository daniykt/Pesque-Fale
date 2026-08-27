import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/config/app_config.dart';

/// Serviço de conexão com o gateway de chat via Socket.IO.
/// Uma instância por tela de chat — abre no initState, fecha no dispose.
class ChatSocketService {
  ChatSocketService({required this.token});

  final String token;
  io.Socket? _socket;

  /// Conecta ao servidor. Callbacks devem ser registrados após chamar connect().
  void connect() {
    _socket = io.io(
      // O gateway de Socket.IO roda na raiz do servidor HTTP, não sob /v1.
      AppConfig.apiBaseUrl.replaceFirst('/v1', ''),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionDelay(2000)
          .build(),
    );
    _socket!.connect();
  }

  void on(String evento, void Function(dynamic) callback) =>
      _socket?.on(evento, callback);

  void off(String evento) => _socket?.off(evento);

  void emit(String evento, [dynamic dados]) => _socket?.emit(evento, dados);

  bool get conectado => _socket?.connected ?? false;

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
