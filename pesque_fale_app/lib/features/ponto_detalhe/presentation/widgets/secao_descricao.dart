import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'secao_titulo.dart';

class SecaoDescricao extends StatelessWidget {
  const SecaoDescricao({super.key, required this.descricao});

  final String? descricao;

  @override
  Widget build(BuildContext context) {
    if (descricao == null || descricao!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SecaoTitulo('SOBRE'),
          const SizedBox(height: AppSpacing.xs),
          Text(descricao!, style: TextStyle(color: colors.textPrimary)),
        ],
      ),
    );
  }
}
