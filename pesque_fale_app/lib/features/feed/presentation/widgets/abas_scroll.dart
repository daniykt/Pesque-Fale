import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/aba_feed.dart';
import '../../providers/feed_provider.dart';

/// Largura do fade na borda direita que indica que há mais abas para rolar.
const double _larguraFade = 24;

class AbasScroll extends StatelessWidget {
  const AbasScroll({super.key});

  @override
  Widget build(BuildContext context) {
    final abaAtiva = context.watch<FeedProvider>().abaAtiva;

    return SizedBox(
      height: 64,
      // Máscara de opacidade (não depende do tema): as abas somem aos poucos
      // na borda direita, sinalizando que a lista continua.
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) {
          final inicioFade = bounds.width <= _larguraFade
              ? 0.0
              : 1 - _larguraFade / bounds.width;
          return LinearGradient(
            colors: const [Colors.black, Colors.black, Colors.transparent],
            stops: [0, inicioFade, 1],
          ).createShader(bounds);
        },
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
              // No fim da rolagem o fade cai neste espaço e a última aba
              // fica inteira visível.
              const SizedBox(width: _larguraFade),
            ],
          ),
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
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: ativa ? colors.primary : Colors.transparent,
          border: ativa ? null : Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              aba.icone,
              size: 16,
              color: ativa ? Colors.white : colors.primaryAccent,
            ),
            const SizedBox(width: 6),
            Text(
              aba.label,
              style: TextStyle(
                color: ativa ? Colors.white : colors.primaryAccent,
                fontWeight: ativa ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
