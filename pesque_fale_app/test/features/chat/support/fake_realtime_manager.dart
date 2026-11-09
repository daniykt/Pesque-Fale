import 'package:pesque_fale_app/core/realtime/realtime_manager.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';

/// [RealtimeManager] sem socket: guarda as assinaturas e deixa o teste
/// disparar eventos, reconexões e mudanças de conexão à mão.
class FakeRealtimeManager extends RealtimeManager {
  FakeRealtimeManager({bool conectado = false}) : _conectadoFake = conectado;

  final Map<String, List<void Function(dynamic)>> assinantes = {};
  final List<void Function()> callbacksReconexao = [];

  /// O que foi enviado via [emit], como `MapEntry(evento, payload)`.
  final List<MapEntry<String, dynamic>> emitidos = [];

  bool _conectadoFake;

  @override
  bool get conectado => _conectadoFake;

  /// Se os listeners de conexão (`addListener`) ainda estão registrados.
  bool get temOuvintes => hasListeners;

  @override
  void reagirAuth(AuthProvider auth) {}

  /// Mesma semântica do real: desconectado, o emit é descartado.
  @override
  void emit(String evento, [dynamic payload]) {
    if (!_conectadoFake) return;
    emitidos.add(MapEntry(evento, payload));
  }

  /// Muda o estado de conexão e notifica, como o `_setConectado` do real.
  void definirConectado(bool valor) {
    if (_conectadoFake == valor) return;
    _conectadoFake = valor;
    notifyListeners();
  }

  bool foiEmitido(String evento) => emitidos.any((e) => e.key == evento);

  @override
  void subscribe(String evento, void Function(dynamic) callback) {
    assinantes.putIfAbsent(evento, () => []).add(callback);
  }

  @override
  void unsubscribe(String evento, void Function(dynamic) callback) {
    assinantes[evento]?.remove(callback);
  }

  @override
  void onReconnect(void Function() callback) {
    callbacksReconexao.add(callback);
  }

  @override
  void removerOnReconnect(void Function() callback) {
    callbacksReconexao.remove(callback);
  }

  void emitir(String evento, dynamic payload) {
    for (final callback in List.of(assinantes[evento] ?? const [])) {
      callback(payload);
    }
  }

  void simularReconexao() {
    for (final callback in List.of(callbacksReconexao)) {
      callback();
    }
  }
}
