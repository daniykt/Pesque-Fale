import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/notificacoes/providers/badge_notificacoes_provider.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import 'main_shell.dart';

/// Menu inferior para telas empilhadas por cima do [MainShell]
/// (ex.: perfil de terceiros). Reusa o [AppBottomNav] e, ao tocar numa aba,
/// volta até '/home' e seleciona a aba escolhida.
class ShellBottomNav extends StatelessWidget {
  const ShellBottomNav({super.key, this.onSelecionarAba});

  /// Injetável para testes. Padrão: MainShell.shellKey.currentState?.selecionarAba.
  final ValueChanged<int>? onSelecionarAba;

  @override
  Widget build(BuildContext context) {
    final abaAtual =
        MainShell.shellKey.currentState?.abaAtual ?? MainShell.inicioIndex;
    final notifCount = context.watch<BadgeNotificacoesProvider>().naoLidas;

    return AppBottomNav(
      currentIndex: abaAtual,
      notifCount: notifCount,
      onDestinationSelected: (index) {
        final selecionar =
            onSelecionarAba ??
            (i) => MainShell.shellKey.currentState?.selecionarAba(i);
        // `|| route.isFirst` impede esvaziar a pilha se '/home' não estiver nela.
        Navigator.of(context).popUntil(
          (route) => route.settings.name == '/home' || route.isFirst,
        );
        selecionar(index);
      },
    );
  }
}
