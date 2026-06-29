import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.notifCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  final int notifCount;

  @override
  Widget build(BuildContext context) {
    final badgeColor = Theme.of(context).extension<AppColors>()!.badge;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_outlined),
          label: 'Início',
        ),
        const NavigationDestination(
          icon: Icon(Icons.search),
          selectedIcon: Icon(Icons.search),
          label: 'Pesquisa',
        ),
        const NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble_outline),
          label: 'Chat',
        ),
        NavigationDestination(
          icon: Badge(
            backgroundColor: badgeColor,
            isLabelVisible: notifCount > 0,
            label: Text(notifCount > 9 ? '9+' : '$notifCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
          selectedIcon: Badge(
            backgroundColor: badgeColor,
            isLabelVisible: notifCount > 0,
            label: Text(notifCount > 9 ? '9+' : '$notifCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
          label: 'Alertas',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    );
  }
}
