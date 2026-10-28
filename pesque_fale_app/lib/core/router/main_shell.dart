import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/assistente/presentation/widgets/botao_ajuda_assistente.dart';
import '../../features/chat/presentation/inbox_page.dart';
import '../../features/chat/providers/badge_mensagens_provider.dart';
import '../../features/feed/presentation/feed_page.dart';
import '../../features/notificacoes/presentation/notificacoes_page.dart';
import '../../features/notificacoes/providers/badge_notificacoes_provider.dart';
import '../../features/perfil/presentation/perfil_page.dart';
import '../../features/pesquisa/presentation/pesquisa_page.dart';
import '../../features/tour/presentation/widgets/tour_overlay.dart';
import '../../features/tour/providers/tour_provider.dart';
import '../../shared/widgets/app_bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Permite que rotas empurradas por cima do shell (ex.: detalhe de ponto)
  /// troquem de aba ao voltar, já que não são descendentes deste widget.
  static final GlobalKey<MainShellState> shellKey = GlobalKey<MainShellState>();

  static const int inicioIndex = 0;
  static const int pesquisaIndex = 1;
  static const int alertasIndex = 3;
  static const int perfilIndex = 4;

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _titles = ['Início', 'Pesquisa', 'Chat', 'Alertas', 'Perfil'];

  static const int _pesquisaIndex = MainShell.pesquisaIndex;
  static const int _chatIndex = 2;
  static const int _alertasIndex = MainShell.alertasIndex;

  List<Widget> _buildScreens() => [
    const FeedPage(),
    const PesquisaPage(),
    const InboxPage(),
    NotificacoesPage(ativa: _currentIndex == _alertasIndex),
    const PerfilPage(),
  ];

  void selecionarAba(int index) => _trocarAba(index);

  /// Aba visível no shell. Lida por telas empilhadas por cima dele, que
  /// precisam destacar a aba de origem no próprio menu inferior.
  int get abaAtual => _currentIndex;

  // Badges de chat e notificações derivam de providers globais mantidos via
  // realtime — o shell não faz polling.
  void _trocarAba(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final naTelaDePesquisa = _currentIndex == _pesquisaIndex;
    final naTelaDeChat = _currentIndex == _chatIndex;
    final notifCount = context.watch<BadgeNotificacoesProvider>().naoLidas;
    final chatCount = context.watch<BadgeMensagensProvider>().naoLidas;

    final passoDoTour = context.watch<TourProvider>().passoAtual;
    final mostrarFabAjuda =
        passoDoTour == null ||
        passoDoTour.index == TourProvider.roteiro.length - 1;
    if (passoDoTour != null && passoDoTour.abaAlvo != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentIndex != passoDoTour.abaAlvo) {
          setState(() => _currentIndex = passoDoTour.abaAlvo);
        }
      });
    }

    return Scaffold(
      appBar: naTelaDePesquisa || naTelaDeChat
          ? null
          : AppBar(title: Text(_titles[_currentIndex])),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _buildScreens()),
          const TourOverlay(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        notifCount: notifCount,
        chatCount: chatCount,
        highlightedIndex: passoDoTour?.abaAlvo,
        onDestinationSelected: _trocarAba,
      ),
      floatingActionButton: mostrarFabAjuda
          ? const BotaoAjudaAssistente()
          : null,
      floatingActionButtonLocation: naTelaDePesquisa
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
