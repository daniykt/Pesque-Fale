import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class ContadorBio extends StatelessWidget {
  const ContadorBio({super.key, required this.tamanhoAtual, this.limite = 300});

  final int tamanhoAtual;
  final int limite;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final estourou = tamanhoAtual > limite;

    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$tamanhoAtual/$limite',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: estourou ? colors.danger : colors.textSecondary,
        ),
      ),
    );
  }
}
