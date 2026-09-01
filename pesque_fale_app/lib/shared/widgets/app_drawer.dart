import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/tour/providers/tour_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              child: Row(
                children: [
                  const Icon(Icons.set_meal_outlined, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Pesque & Fale',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Sobre Nós'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Reiniciar Tour'),
              onTap: () {
                Navigator.pop(context);
                context.read<TourProvider>().iniciarManual();
              },
            ),
          ],
        ),
      ),
    );
  }
}
