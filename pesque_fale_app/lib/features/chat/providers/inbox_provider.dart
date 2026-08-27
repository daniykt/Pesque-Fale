import 'package:flutter/foundation.dart';

import '../data/conversas_repository.dart';
import '../domain/conversa.dart';

enum StatusInbox { carregando, carregado, erro }

class InboxProvider extends ChangeNotifier {
  InboxProvider({required this.repository});

  final ConversasRepository repository;

  StatusInbox status = StatusInbox.carregando;
  List<Conversa> _todas = [];
  String _termoBusca = '';

  /// Retorna as conversas filtradas:
  /// - Sempre remove chats vazios (ultimaMensagem == null)
  /// - Aplica termo de busca por outroNome/outroUsername
  List<Conversa> get conversas {
    final comMensagem = _todas.where((c) => c.temMensagem);
    if (_termoBusca.trim().isEmpty) return comMensagem.toList();
    final termo = _termoBusca.toLowerCase().trim();
    return comMensagem
        .where(
          (c) =>
              c.outroNome.toLowerCase().contains(termo) ||
              c.outroUsername.toLowerCase().contains(termo),
        )
        .toList();
  }

  String get termoBusca => _termoBusca;
  bool get temAlgumaConversa => _todas.any((c) => c.temMensagem);

  Future<void> carregar() async {
    status = StatusInbox.carregando;
    notifyListeners();
    try {
      _todas = await repository.listar();
      status = StatusInbox.carregado;
    } catch (_) {
      status = StatusInbox.erro;
    }
    notifyListeners();
  }

  void setTermoBusca(String termo) {
    _termoBusca = termo;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      _todas = await repository.listar();
      status = StatusInbox.carregado;
    } catch (_) {
      // Silencia erro no refresh — mantém os dados já carregados na tela.
    }
    notifyListeners();
  }
}
