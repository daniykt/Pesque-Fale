import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.notifCount = 0,
    this.highlightedIndex,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  final int notifCount;

  /// Índice do item a destacar com uma borda (usado pelo tour guiado).
  /// `null` mantém o comportamento normal.
  final int? highlightedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final badgeColor = colors.badge;

    Widget destacar(Widget icone, int index) {
      if (highlightedIndex != index) return icone;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        decoration: BoxDecoration(
          border: Border.all(color: colors.primary, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: icone,
      );
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: destacar(const Icon(Icons.home_outlined), 0),
          selectedIcon: destacar(const Icon(Icons.home_outlined), 0),
          label: 'Início',
        ),
        NavigationDestination(
          icon: destacar(const Icon(Icons.search), 1),
          selectedIcon: destacar(const Icon(Icons.search), 1),
          label: 'Pesquisa',
        ),
        NavigationDestination(
          icon: destacar(const Icon(Icons.chat_bubble_outline), 2),
          selectedIcon: destacar(const Icon(Icons.chat_bubble_outline), 2),
          label: 'Chat',
        ),
        NavigationDestination(
          icon: destacar(
            Badge(
              backgroundColor: badgeColor,
              isLabelVisible: notifCount > 0,
              label: Text(notifCount > 99 ? '99+' : '$notifCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            3,
          ),
          selectedIcon: destacar(
            Badge(
              backgroundColor: badgeColor,
              isLabelVisible: notifCount > 0,
              label: Text(notifCount > 99 ? '99+' : '$notifCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            3,
          ),
          label: 'Alertas',
        ),
        NavigationDestination(
          icon: destacar(const Icon(Icons.person_outline), 4),
          selectedIcon: destacar(const Icon(Icons.person_outline), 4),
          label: 'Perfil',
        ),
      ],
    );
  }
}
