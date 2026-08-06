import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

class EventoCardSkeleton extends StatefulWidget {
  const EventoCardSkeleton({super.key});

  @override
  State<EventoCardSkeleton> createState() => _EventoCardSkeletonState();
}

class _EventoCardSkeletonState extends State<EventoCardSkeleton>
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
      child: SizedBox(
        height: 300,
        child: ClipRRect(
          borderRadius: AppRadius.mdRadius,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: colors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 160, color: colors.surfaceVariant),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(colors, width: 60, height: 18),
                      const SizedBox(height: AppSpacing.xs),
                      _box(colors, width: 180, height: 16),
                      const SizedBox(height: AppSpacing.xs),
                      _box(colors, width: 120, height: 12),
                      const SizedBox(height: AppSpacing.xxs),
                      _box(colors, width: 200, height: 12),
                    ],
                  ),
                ),
              ],
            ),
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
      child: Container(
        width: width,
        height: height,
        color: colors.surfaceVariant,
      ),
    );
  }
}
