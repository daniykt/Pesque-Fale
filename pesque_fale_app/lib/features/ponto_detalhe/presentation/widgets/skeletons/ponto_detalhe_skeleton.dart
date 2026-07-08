import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import 'avaliacao_card_skeleton.dart';

class PontoDetalheSkeleton extends StatefulWidget {
  const PontoDetalheSkeleton({super.key});

  @override
  State<PontoDetalheSkeleton> createState() => _PontoDetalheSkeletonState();
}

class _PontoDetalheSkeletonState extends State<PontoDetalheSkeleton>
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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(height: 240, color: colors.surfaceVariant),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(colors, width: 200, height: 24),
                const SizedBox(height: AppSpacing.xs),
                _box(colors, width: 90, height: 24),
                const SizedBox(height: AppSpacing.sm),
                _box(colors, width: 160, height: 14),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(child: _box(colors, width: double.infinity, height: 44)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _box(colors, width: double.infinity, height: 44)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < 3; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(colors, width: 80, height: 12),
                  const SizedBox(height: AppSpacing.xs),
                  _box(colors, width: double.infinity, height: 14),
                  const SizedBox(height: AppSpacing.xxs),
                  _box(colors, width: 220, height: 14),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AvaliacaoCardSkeleton(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(AppColors colors, {required double width, required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(width: width, height: height, color: colors.surfaceVariant),
    );
  }
}
