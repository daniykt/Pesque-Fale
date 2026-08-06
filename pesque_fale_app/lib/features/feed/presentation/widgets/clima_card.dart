import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

class ClimaCard extends StatelessWidget {
  const ClimaCard({super.key});

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
          const Row(
            children: [
              Icon(Icons.wb_sunny, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Clima Agora',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '28°C',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ensolarado · Condições ótimas para pesca',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text('🌬️ Vento: 12 km/h'),
          const SizedBox(height: 4),
          const Text('💧 Umidade: 65%'),
          const SizedBox(height: 4),
          const Text('🎣 Melhor período: 06h - 10h'),
        ],
      ),
    );
  }
}
