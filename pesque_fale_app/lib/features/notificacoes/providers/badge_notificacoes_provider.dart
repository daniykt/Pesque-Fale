import 'package:flutter/foundation.dart';

import '../data/notificacoes_repository.dart';

class BadgeNotificacoesProvider extends ChangeNotifier {
  BadgeNotificacoesProvider({required this.repository});

  final NotificacoesRepository repository;

  int _naoLidas = 0;
  int _geracao = 0;
  int? _geracaoEmBusca;

  int get naoLidas => _naoLidas;

  Future<void> atualizar() async {
    final geracao = _geracao;
    if (_geracaoEmBusca == geracao) return;
    _geracaoEmBusca = geracao;
    try {
      final n = await repository.contarNaoLidas();
      if (geracao != _geracao || n == _naoLidas) return;
      _naoLidas = n;
      notifyListeners();
    } catch (_) {
      return;
    } finally {
      if (_geracaoEmBusca == geracao) _geracaoEmBusca = null;
    }
  }

  void zerar() {
    _geracao++;
    if (_naoLidas != 0) {
      _naoLidas = 0;
      notifyListeners();
    }
  }

  void resetar() {
    _geracao++;
    _geracaoEmBusca = null;
    _naoLidas = 0;
    notifyListeners();
  }
}