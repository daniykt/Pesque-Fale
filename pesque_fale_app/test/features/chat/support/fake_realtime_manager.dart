import 'package:pesque_fale_app/core/realtime/realtime_manager.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';

/// [RealtimeManager] sem socket: guarda as assinaturas e deixa o teste
/// disparar eventos e reconexões à mão.
class FakeRealtimeManager extends RealtimeManager {
  final Map<String, List<void Function(dynamic)>> assinantes = {};
  final List<void Function()> callbacksReconexao = [];

  @override
  void reagirAuth(AuthProvider auth) {}

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
