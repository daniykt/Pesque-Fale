import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

class DicaDoDiaCard extends StatelessWidget {
  const DicaDoDiaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phishing, color: colors.primary),
              const SizedBox(width: 8),
              const Text(
                'Dica do dia',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tucunaré ataca melhor com isca artificial de manhã. Use cores '
            'vibrantes em dias ensolarados.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
