import 'package:flutter/material.dart';

import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_drawer.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const int _notifCount = 0;

  static const _titles = ['Início', 'Pesquisa', 'Chat', 'Alertas', 'Perfil'];

  // Placeholders — cada um vira lib/features/<tela>/ na Fase 1.
  static const _placeholderScreens = [
    _PlaceholderScreen(label: 'Início', icon: Icons.home_outlined),
    _PlaceholderScreen(label: 'Pesquisa', icon: Icons.search),
    _PlaceholderScreen(label: 'Chat', icon: Icons.chat_bubble_outline),
    _PlaceholderScreen(label: 'Alertas', icon: Icons.notifications_outlined),
    _PlaceholderScreen(label: 'Perfil', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _placeholderScreens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        notifCount: _notifCount,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Tela ainda não implementada (Fase 1+)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}