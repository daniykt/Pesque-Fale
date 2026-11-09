import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class NotaSelector extends StatelessWidget {
  const NotaSelector({super.key, required this.nota, required this.onChanged});

  final double nota;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) => _estrela(i)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${nota.toStringAsFixed(1)} / 5.0',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _estrela(int indice) {
    final valorEsquerda = indice + 0.5;
    final valorDireita = indice + 1.0;

    IconData icone;
    if (nota >= valorDireita) {
      icone = Icons.star;
    } else if (nota >= valorEsquerda) {
      icone = Icons.star_half;
    } else {
      icone = Icons.star_border;
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        children: [
          Positioned.fill(child: Icon(icone, size: 40, color: Colors.amber)),
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(valorEsquerda.clamp(1.0, 5.0)),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(valorDireita),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
