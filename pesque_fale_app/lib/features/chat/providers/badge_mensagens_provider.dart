import 'package:flutter/foundation.dart';

import 'inbox_provider.dart';

/// Mantém a contagem de **conversas com mensagens não-lidas** para o badge
/// do ícone de Chat no bottom nav. Não busca nada sozinho: deriva da lista
/// do [InboxProvider] global, que se mantém em dia via realtime, e notifica
/// só quando a contagem muda.
///
/// A contagem é por conversa, não por mensagem — padrão WhatsApp. Mantém
/// o número estável e evita o visual de "99+" o tempo todo em usuários
/// com muitas mensagens em uma única conversa.
class BadgeMensagensProvider extends ChangeNotifier {
  BadgeMensagensProvider({required this.inbox}) {
    // Escuta o inbox só pra LER a lista. Nenhum listener aqui pode alterar
    // o InboxProvider: isso reentraria no notifyListeners dele.
    inbox.addListener(_recalcular);
    _recalcular();
  }

  final InboxProvider inbox;
  int _naoLidas = 0;

  /// Número de conversas (não de mensagens) que tem pelo menos uma mensagem
  /// não lida pra esse usuário.
  int get naoLidas => _naoLidas;

  void _recalcular() {
    final n = inbox.conversasInternas.where((c) => c.naoLidas > 0).length;
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
    inbox.removeListener(_recalcular);
    super.dispose();
  }
}
