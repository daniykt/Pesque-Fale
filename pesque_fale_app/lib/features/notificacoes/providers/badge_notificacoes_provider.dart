import 'package:flutter/foundation.dart';

import 'notificacoes_provider.dart';

/// Mantém a contagem de notificações não vistas para o badge do ícone de
/// Alertas no bottom nav. Não busca nada sozinho: deriva do
/// [NotificacoesProvider] global, que se mantém em dia via realtime, e
/// notifica só quando a contagem muda.
class BadgeNotificacoesProvider extends ChangeNotifier {
  BadgeNotificacoesProvider({required this.notificacoes}) {
    // Escuta o provider só pra LER a contagem. Nenhum listener aqui pode
    // alterar o NotificacoesProvider: isso reentraria no notifyListeners dele.
    notificacoes.addListener(_recalcular);
    _recalcular();
  }

  final NotificacoesProvider notificacoes;
  int _naoLidas = 0;

  int get naoLidas => _naoLidas;

  void _recalcular() {
    final n = notificacoes.naoVistas;
    if (n == _naoLidas) return;
    _naoLidas = n;
    notifyListeners();
  }

  void zerar() {
    if (_naoLidas != 0) {
      _naoLidas = 0;
      notifyListeners();
    }
  }

  void resetar() {
    _naoLidas = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    notificacoes.removeListener(_recalcular);
    super.dispose();
  }
}
