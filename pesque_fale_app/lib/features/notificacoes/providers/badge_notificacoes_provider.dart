import 'package:flutter/foundation.dart';

import '../data/notificacoes_repository.dart';

class BadgeNotificacoesProvider extends ChangeNotifier {
  BadgeNotificacoesProvider({required this.repository});

  final NotificacoesRepository repository;

  int _naoLidas = 0;
  int get naoLidas => _naoLidas;

  Future<void> atualizar() async {
    try {
      final n = await repository.contarNaoLidas();
      if (n != _naoLidas) {
        _naoLidas = n;
        notifyListeners();
      }
    } catch (_) {
      // Silencia erro — mantém o contador já exibido.
    }
  }

  void zerar() {
    if (_naoLidas != 0) {
      _naoLidas = 0;
      notifyListeners();
    }
  }
}
