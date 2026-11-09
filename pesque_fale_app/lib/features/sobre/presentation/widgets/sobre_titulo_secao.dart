import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Rótulo em caixa alta que abre cada seção da tela Sobre Nós.
class SobreTituloSecao extends StatelessWidget {
  const SobreTituloSecao(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        texto.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
