import 'package:flutter/foundation.dart';

import '../data/notificacoes_repository.dart';

class BadgeNotificacoesProvider extends ChangeNotifier {
  BadgeNotificacoesProvider({required this.repository});

  final NotificacoesRepository repository;

  int _naoLidas = 0;
  int _geracao = 0;
  bool _atualizando = false;

  int get naoLidas => _naoLidas;

  Future<void> atualizar() async {
    if (_atualizando) return;
    _atualizando = true;
    final geracao = _geracao;
    try {
      final n = await repository.contarNaoLidas();
      if (geracao != _geracao || n == _naoLidas) return;
      _naoLidas = n;
      notifyListeners();
    } catch (_) {
      return;
    } finally {
      _atualizando = false;
    }
  }

  void zerar() {
    _geracao++;
    if (_naoLidas != 0) {
      _naoLidas = 0;
      notifyListeners();
    }
  }
}