import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

class UsuarioCardSkeleton extends StatefulWidget {
  const UsuarioCardSkeleton({super.key});

  @override
  State<UsuarioCardSkeleton> createState() => _UsuarioCardSkeletonState();
}

class _UsuarioCardSkeletonState extends State<UsuarioCardSkeleton>
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
      builder: (context, child) => Opacity(opacity: _opacity.value, child: child),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: AppRadius.mdRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _box(colors, width: 56, height: 56, radius: 28),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(colors, width: 120, height: 16),
                      const SizedBox(height: AppSpacing.xxs),
                      _box(colors, width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _box(colors, width: double.infinity, height: 12),
            const SizedBox(height: AppSpacing.md),
            _box(colors, width: double.infinity, height: 40, radius: 20),
          ],
        ),
      ),
    );
  }

  Widget _box(
    AppColors colors, {
    required double width,
    required double height,
    double radius = 6,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(width: width, height: height, color: colors.surfaceVariant),
    );
  }
}
