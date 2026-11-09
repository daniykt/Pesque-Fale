import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Label + campo + dica opcional, usado em cada seção do formulário de
/// edição de perfil.
class EditarSecao extends StatelessWidget {
  const EditarSecao({
    super.key,
    required this.label,
    required this.child,
    this.dica,
  });

  final String label;
  final Widget child;
  final String? dica;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          child,
          if (dica != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              dica!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
