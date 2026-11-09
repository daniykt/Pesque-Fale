import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class EstrelasReadonly extends StatelessWidget {
  const EstrelasReadonly({super.key, required this.nota, this.tamanho = 24});

  final double nota;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData icon;
        Color cor;
        if (nota == 0) {
          icon = Icons.star_border;
          cor = colors.textSecondary;
        } else if (index + 1 <= nota) {
          icon = Icons.star;
          cor = Colors.amber[600]!;
        } else if (index + 0.5 <= nota) {
          icon = Icons.star_half;
          cor = Colors.amber[600]!;
        } else {
          icon = Icons.star_border;
          cor = Colors.amber[600]!;
        }
        return Icon(icon, size: tamanho, color: cor);
      }),
    );
  }
}
