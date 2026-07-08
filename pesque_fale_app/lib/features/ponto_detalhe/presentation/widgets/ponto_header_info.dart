import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/tipo_chip.dart';
import '../../../pesquisa/domain/ponto.dart';

class PontoHeaderInfo extends StatelessWidget {
  const PontoHeaderInfo({super.key, required this.ponto});

  final Ponto ponto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ponto.nome,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TipoChip.tinted(tipo: ponto.tipo),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                ponto.avgNota.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                ' (${ponto.totalAvaliacoes} avaliações) · ',
                style: TextStyle(color: colors.textSecondary),
              ),
              Icon(Icons.location_on, size: 16, color: colors.textSecondary),
              const SizedBox(width: 2),
              Text(
                '${ponto.cidade}-${ponto.estado}',
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
