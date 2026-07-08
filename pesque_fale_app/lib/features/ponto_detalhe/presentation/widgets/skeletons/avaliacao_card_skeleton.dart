import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

class AvaliacaoCardSkeleton extends StatefulWidget {
  const AvaliacaoCardSkeleton({super.key});

  @override
  State<AvaliacaoCardSkeleton> createState() => _AvaliacaoCardSkeletonState();
}

class _AvaliacaoCardSkeletonState extends State<AvaliacaoCardSkeleton>
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
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _box(colors, width: 40, height: 40, circle: true),
                const SizedBox(width: AppSpacing.xs),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(colors, width: 100, height: 14),
                    const SizedBox(height: AppSpacing.xxs),
                    _box(colors, width: 70, height: 12),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            _box(colors, width: 110, height: 14),
            const SizedBox(height: AppSpacing.xs),
            _box(colors, width: double.infinity, height: 14),
            const SizedBox(height: AppSpacing.xxs),
            _box(colors, width: 180, height: 14),
          ],
        ),
      ),
    );
  }

  Widget _box(
    AppColors colors, {
    required double width,
    required double height,
    bool circle = false,
  }) {
    return ClipRRect(
      borderRadius: circle
          ? BorderRadius.circular(height / 2)
          : BorderRadius.circular(4),
      child: Container(
        width: width,
        height: height,
        color: colors.surfaceVariant,
      ),
    );
  }
}
