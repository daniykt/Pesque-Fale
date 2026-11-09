import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/tour_provider.dart';
import 'tour_card.dart';

/// Overlay global do tour guiado: backdrop escuro + card modal central.
/// Renderiza vazio quando não há tour ativo.
class TourOverlay extends StatelessWidget {
  const TourOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final tourProvider = context.watch<TourProvider>();
    final passo = tourProvider.passoAtual;

    if (passo == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: TourCard(
              key: ValueKey(passo.index),
              passo: passo,
              total: TourProvider.roteiro.length,
              onAnterior: tourProvider.voltar,
              onProximo: tourProvider.avancar,
              onPular: tourProvider.pular,
            ),
          ),
        ),
      ],
    );
  }
}
