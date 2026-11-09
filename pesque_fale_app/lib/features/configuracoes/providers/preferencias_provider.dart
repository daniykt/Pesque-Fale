import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO(henrique): mover para GET/PATCH /usuarios/me quando o backend
// suportar o campo notificacoes_ativas.
class PreferenciasProvider extends ChangeNotifier {
  static const _chaveNotificacoesAtivas = 'preferencias.notificacoes_ativas';

  bool _notificacoesAtivas = true;
  bool get notificacoesAtivas => _notificacoesAtivas;

  PreferenciasProvider() {
    _carregarPrefs();
  }

  Future<void> _carregarPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _notificacoesAtivas =
        prefs.getBool(_chaveNotificacoesAtivas) ?? _notificacoesAtivas;
    notifyListeners();
  }

  Future<void> setNotificacoesAtivas(bool valor) async {
    _notificacoesAtivas = valor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveNotificacoesAtivas, valor);
  }
}
