import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// Tags da publicação em pílulas. Sem padding próprio: cada tela põe o seu.
class TagsPublicacao extends StatelessWidget {
  const TagsPublicacao({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primaryAccent.withValues(alpha: 0.15),
              borderRadius: AppRadius.pillRadius,
            ),
            child: Text(
              '#$tag',
              style: TextStyle(color: colors.primaryAccent, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
