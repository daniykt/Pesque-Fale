import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class PerfilSkeleton extends StatefulWidget {
  const PerfilSkeleton({super.key});

  @override
  State<PerfilSkeleton> createState() => _PerfilSkeletonState();
}

class _PerfilSkeletonState extends State<PerfilSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.35,
      end: 0.7,
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
      builder: (context, child) {
        return Opacity(opacity: _opacity.value, child: child);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(color: colors.surfaceVariant),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl + AppSpacing.xxs),
                _bar(colors, width: 160, height: 20),
                const SizedBox(height: AppSpacing.xs),
                _bar(colors, width: 100, height: 14),
                const SizedBox(height: AppSpacing.sm),
                _bar(colors, width: double.infinity, height: 14),
                const SizedBox(height: AppSpacing.xxs),
                _bar(colors, width: 220, height: 14),
                const SizedBox(height: AppSpacing.lg),
                _bar(colors, width: double.infinity, height: 44),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(AppColors colors, {required double width, required double height}) {
    return ClipRRect(
      borderRadius: AppRadius.smRadius,
      child: Container(width: width, height: height, color: colors.surfaceVariant),
    );
  }
}
