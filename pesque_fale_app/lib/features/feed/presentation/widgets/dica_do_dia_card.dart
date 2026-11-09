import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/dicas_de_pesca.dart';

class DicaDoDiaCard extends StatelessWidget {
  const DicaDoDiaCard({super.key, this.data});

  final DateTime? data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textos = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phishing, color: colors.primaryAccent, size: 28),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Dica do dia',
                style: textos.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(dicaDoDia(data ?? DateTime.now()), style: textos.bodyLarge),
        ],
      ),
    );
  }
}
