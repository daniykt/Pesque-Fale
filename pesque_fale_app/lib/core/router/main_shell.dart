import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/chat/data/conversas_repository.dart';
import '../../features/chat/presentation/inbox_page.dart';
import '../../features/chat/providers/inbox_provider.dart';
import '../../features/feed/presentation/feed_page.dart';
import '../../features/notificacoes/data/notificacoes_repository.dart';
import '../../features/notificacoes/presentation/notificacoes_page.dart';
import '../../features/notificacoes/providers/badge_notificacoes_provider.dart';
import '../../features/notificacoes/providers/notificacoes_provider.dart';
import '../../features/perfil/data/perfil_repository.dart';
import '../../features/perfil/presentation/perfil_page.dart';
import '../../features/perfil/presentation/widgets/perfil_opcoes_sheet.dart';
import '../../features/pesquisa/presentation/pesquisa_page.dart';
import '../../features/tour/presentation/widgets/tour_overlay.dart';
import '../../features/tour/providers/tour_provider.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_drawer.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Permite que rotas empurradas por cima do shell (ex.: detalhe de ponto)
  /// troquem de aba ao voltar, já que não são descendentes deste widget.
  static final GlobalKey<MainShellState> shellKey = GlobalKey<MainShellState>();

  static const int inicioIndex = 0;
  static const int pesquisaIndex = 1;
  static const int alertasIndex = 3;
  static const int perfilIndex = 4;
  static const Duration intervaloBadge = Duration(seconds: 30);

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _timerBadge;

  static const _titles = ['Início', 'Pesquisa', 'Chat', 'Alertas', 'Perfil'];

  static const int _pesquisaIndex = MainShell.pesquisaIndex;
  static const int _chatIndex = 2;
  static const int _alertasIndex = MainShell.alertasIndex;
  static const int _perfilIndex = MainShell.perfilIndex;

  List<Widget> _buildScreens() => [
    const FeedPage(),
    const PesquisaPage(),
    ChangeNotifierProvider<InboxProvider>(
      create: (ctx) =>
          InboxProvider(repository: ctx.read<ConversasRepository>()),
      child: const InboxPage(),
    ),
    ChangeNotifierProvider<NotificacoesProvider>(
      create: (ctx) => NotificacoesProvider(
        repository: ctx.read<NotificacoesRepository>(),
        perfilRepository: ctx.read<PerfilRepository>(),
      ),
      child: NotificacoesPage(ativa: _currentIndex == _alertasIndex),
    ),
    const PerfilPage(),
  ];

  void selecionarAba(int index) => _trocarAba(index);

  /// Aba visível no shell. Lida por telas empilhadas por cima dele, que
  /// precisam destacar a aba de origem no próprio menu inferior.
  int get abaAtual => _currentIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timerBadge = Timer.periodic(
      MainShell.intervaloBadge,
      (_) => _atualizarBadge(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _atualizarBadge());
  }

  @override
  void dispose() {
    _timerBadge?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _atualizarBadge();
  }

  void _trocarAba(int index) {
    setState(() => _currentIndex = index);
    _atualizarBadge();
  }

  void _atualizarBadge() {
    if (!mounted || _currentIndex == _alertasIndex) return;
    context.read<BadgeNotificacoesProvider>().atualizar();
  }

  @override
  Widget build(BuildContext context) {
    final naTelaDePerfil = _currentIndex == _perfilIndex;
    final naTelaDePesquisa = _currentIndex == _pesquisaIndex;
    final naTelaDeChat = _currentIndex == _chatIndex;
    final notifCount = context.watch<BadgeNotificacoesProvider>().naoLidas;

    final passoDoTour = context.watch<TourProvider>().passoAtual;
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
          : AppBar(
              title: Text(_titles[_currentIndex]),
              leading: naTelaDePerfil
                  ? Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => PerfilOpcoesSheet.show(context),
                      ),
                    )
                  : null,
            ),
      drawer: naTelaDePerfil || naTelaDePesquisa || naTelaDeChat
          ? null
          : const AppDrawer(),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _buildScreens()),
          const TourOverlay(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        notifCount: notifCount,
        highlightedIndex: passoDoTour?.abaAlvo,
        onDestinationSelected: _trocarAba,
      ),
    );
  }
}