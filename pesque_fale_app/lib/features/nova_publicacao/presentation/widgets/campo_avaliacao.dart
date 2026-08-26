import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class CampoAvaliacao extends StatelessWidget {
  const CampoAvaliacao({
    super.key,
    required this.nota,
    required this.onChanged,
  });

  final double? nota;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notaAtual = nota ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Avaliação do local',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(opcional)',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Se quiser, avalie o local para ajudar outros pescadores.',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: List.generate(5, (index) {
            final preenchida = index + 1 <= notaAtual;
            return InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onChanged((index + 1).toDouble()),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  preenchida ? Icons.star : Icons.star_border,
                  size: 32,
                  color: preenchida ? Colors.amber[600] : colors.textSecondary,
                ),
              ),
            );
          }),
        ),
        if (nota != null && nota! > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => onChanged(null),
              child: const Text('Limpar avaliação'),
            ),
          ),
      ],
    );
  }
}
