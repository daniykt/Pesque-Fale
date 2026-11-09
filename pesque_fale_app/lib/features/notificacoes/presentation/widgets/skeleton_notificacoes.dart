import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class SkeletonNotificacoes extends StatefulWidget {
  const SkeletonNotificacoes({super.key});

  @override
  State<SkeletonNotificacoes> createState() => _SkeletonNotificacoesState();
}

class _SkeletonNotificacoesState extends State<SkeletonNotificacoes>
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
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (context, index) => _linhaSkeleton(colors),
      ),
    );
  }

  Widget _linhaSkeleton(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _circle(colors, 48),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(colors, width: double.infinity, height: 14),
                const SizedBox(height: 6),
                _box(colors, width: 140, height: 12),
                const SizedBox(height: 6),
                _box(colors, width: 60, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(AppColors colors, double tamanho) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(tamanho / 2),
      child: Container(width: tamanho, height: tamanho, color: colors.surfaceVariant),
    );
  }

  Widget _box(AppColors colors, {required double width, required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(width: width, height: height, color: colors.surfaceVariant),
    );
  }
}
