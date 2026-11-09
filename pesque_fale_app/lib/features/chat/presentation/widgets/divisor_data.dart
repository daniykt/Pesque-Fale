import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DivisorData extends StatelessWidget {
  const DivisorData({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          texto,
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}
