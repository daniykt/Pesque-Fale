import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/aba_feed.dart';
import '../../providers/feed_provider.dart';

class AbasScroll extends StatelessWidget {
  const AbasScroll({super.key});

  @override
  Widget build(BuildContext context) {
    final abaAtiva = context.watch<FeedProvider>().abaAtiva;

    return SizedBox(
      height: 52,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 12),
            for (final aba in AbaFeed.values) ...[
              _AbaChip(
                aba: aba,
                ativa: aba == abaAtiva,
                onTap: () => context.read<FeedProvider>().trocarAba(aba),
              ),
              const SizedBox(width: 8),
            ],
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _AbaChip extends StatelessWidget {
  const _AbaChip({required this.aba, required this.ativa, required this.onTap});

  final AbaFeed aba;
  final bool ativa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: ativa ? colors.primary : Colors.transparent,
          border: ativa ? null : Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              aba.icone,
              size: 16,
              color: ativa ? Colors.white : colors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              aba.label,
              style: TextStyle(
                color: ativa ? Colors.white : colors.primary,
                fontWeight: ativa ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
