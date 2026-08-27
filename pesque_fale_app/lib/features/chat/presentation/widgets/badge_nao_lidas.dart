import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class BadgeNaoLidas extends StatelessWidget {
  const BadgeNaoLidas({super.key, required this.quantidade});

  final int quantidade;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final texto = quantidade > 99 ? '99+' : '$quantidade';

    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
