import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../providers/perfil_provider.dart';

/// Linha discreta que explica a ausência do botão "Mensagem" quando o follow
/// é unilateral — o chat só abre com reciprocidade, regra enforçada no
/// gateway de chat do backend.
class HintMutualFollow extends StatelessWidget {
  const HintMutualFollow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerfilProvider>();
    if (!provider.mostrarHintMutualFollow) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        'Vocês precisam se seguir mutuamente para conversar por mensagem.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      ),
    );
  }
}
