import 'package:flutter/material.dart';

import '../../../../core/config/app_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class SobreHero extends StatelessWidget {
  const SobreHero({super.key});

  static const double _logoTamanho = 72;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.primary, colors.primary.withValues(alpha: 0.85)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: AppRadius.lgRadius,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/image/logo/logo.jpg',
                fit: BoxFit.cover,
                width: _logoTamanho,
                height: _logoTamanho,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pesque & Fale',
            style: textTheme.displayMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'A rede dos pescadores',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              borderRadius: AppRadius.pillRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  'v${AppInfo.version} · 17 de outubro de 2026',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
