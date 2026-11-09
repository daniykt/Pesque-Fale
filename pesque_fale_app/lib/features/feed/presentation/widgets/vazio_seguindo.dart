import 'package:flutter/material.dart';

import '../../../../core/router/main_shell.dart';
import '../../../../core/theme/app_colors.dart';

class VazioSeguindo extends StatelessWidget {
  const VazioSeguindo({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_off, size: 64, color: colors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Ainda vazio por aqui',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Siga outros pescadores para ver publicações deles no seu feed',
              style: TextStyle(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => MainShell.shellKey.currentState?.selecionarAba(
                MainShell.pesquisaIndex,
              ),
              child: const Text('Explorar pescadores'),
            ),
          ],
        ),
      ),
    );
  }
}
