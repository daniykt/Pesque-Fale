import 'package:flutter/foundation.dart';

import '../data/conversas_repository.dart';

/// Mantém a contagem de **conversas com mensagens não-lidas** para o badge
/// do ícone de Chat no bottom nav. Espelha o padrão do
/// [BadgeNotificacoesProvider]: polling com proteção de concorrência via
/// geração, notifica só quando a contagem muda.
///
/// A contagem é por conversa, não por mensagem — padrão WhatsApp. Mantém
/// o número estável e evita o visual de "99+" o tempo todo em usuários
/// com muitas mensagens em uma única conversa.
class BadgeMensagensProvider extends ChangeNotifier {
  BadgeMensagensProvider({required this.repository});

  final ConversasRepository repository;

  int _naoLidas = 0;
  int _geracao = 0;
  int? _geracaoEmBusca;

  /// Número de conversas (não de mensagens) que tem pelo menos uma mensagem
  /// não lida pra esse usuário.
  int get naoLidas => _naoLidas;

  Future<void> atualizar() async {
    final geracao = _geracao;
    if (_geracaoEmBusca == geracao) return;
    _geracaoEmBusca = geracao;
    try {
      final conversas = await repository.listar();
      final n = conversas.where((c) => c.naoLidas > 0).length;
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
