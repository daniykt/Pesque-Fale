import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

class PublicacaoCardSkeleton extends StatefulWidget {
  const PublicacaoCardSkeleton({super.key});

  @override
  State<PublicacaoCardSkeleton> createState() => _PublicacaoCardSkeletonState();
}

class _PublicacaoCardSkeletonState extends State<PublicacaoCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.4,
      end: 0.75,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) =>
          Opacity(opacity: _opacity.value, child: child),
      child: ClipRRect(
        borderRadius: AppRadius.mdRadius,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: colors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    _circle(colors, 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(colors, width: 140, height: 14),
                          const SizedBox(height: 6),
                          _box(colors, width: 100, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: _box(colors, width: double.infinity, height: 14),
              ),
              const SizedBox(height: AppSpacing.xs),
              AspectRatio(
                aspectRatio: 4 / 5,
                child: Container(color: colors.surfaceVariant),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(colors, width: 160, height: 12),
                    const SizedBox(height: AppSpacing.xs),
                    _box(colors, width: double.infinity, height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(AppColors colors, double tamanho) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(tamanho / 2),
      child: Container(
        width: tamanho,
        height: tamanho,
        color: colors.surfaceVariant,
      ),
    );
  }

  Widget _box(
    AppColors colors, {
    required double width,
    required double height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: width,
        height: height,
        color: colors.surfaceVariant,
      ),
    );
  }
}
