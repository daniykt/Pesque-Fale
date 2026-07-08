import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

class PontoCardSkeleton extends StatefulWidget {
  const PontoCardSkeleton({super.key});

  @override
  State<PontoCardSkeleton> createState() => _PontoCardSkeletonState();
}

class _PontoCardSkeletonState extends State<PontoCardSkeleton>
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
      child: ClipRRect(
        borderRadius: AppRadius.mdRadius,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: colors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 180, color: colors.surfaceVariant),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(colors, width: 60, height: 18),
                    const SizedBox(height: AppSpacing.xs),
                    _box(colors, width: 160, height: 20),
                    const SizedBox(height: AppSpacing.xs),
                    _box(colors, width: 100, height: 14),
                    const SizedBox(height: AppSpacing.xxs),
                    _box(colors, width: 120, height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      child: Container(width: width, height: height, color: colors.surfaceVariant),
    );
  }
}
