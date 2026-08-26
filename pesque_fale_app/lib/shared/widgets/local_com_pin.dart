import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class LocalComPin extends StatelessWidget {
  const LocalComPin({super.key, required this.texto, this.onTap});

  final String texto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final conteudo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 20,
          margin: const EdgeInsets.only(right: 8),
          color: colors.primary,
        ),
        Icon(Icons.location_on, size: 18, color: colors.primary),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: colors.primary,
          ),
        ),
      ],
    );

    if (onTap == null) return conteudo;
    return InkWell(onTap: onTap, child: conteudo);
  }
}
