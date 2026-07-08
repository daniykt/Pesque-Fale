import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SecaoTitulo extends StatelessWidget {
  const SecaoTitulo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Text(
      texto,
      style: TextStyle(
        color: colors.primary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }
}
