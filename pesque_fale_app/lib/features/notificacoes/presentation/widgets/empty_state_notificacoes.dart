import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class EmptyStateNotificacoes extends StatelessWidget {
  const EmptyStateNotificacoes({super.key, required this.comFiltro});

  final bool comFiltro;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: colors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              comFiltro
                  ? 'Nenhuma notificação nesse filtro'
                  : 'Nenhuma notificação aqui',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
