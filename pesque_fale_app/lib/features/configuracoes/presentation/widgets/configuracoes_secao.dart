import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ConfiguracoesSecao extends StatelessWidget {
  const ConfiguracoesSecao({
    super.key,
    required this.titulo,
    required this.itens,
  });

  final String titulo;
  final List<Widget> itens;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            titulo.toUpperCase(),
            style: textTheme.labelLarge?.copyWith(
              color: colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Material(
          color: colors.surface,
          child: Column(
            children: [
              for (var i = 0; i < itens.length; i++) ...[
                itens[i],
                if (i < itens.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
