import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../features/pesquisa/domain/tipo_ponto.dart';
import '../utils/tipo_visuals.dart';

class TipoChip extends StatelessWidget {
  const TipoChip.solid({super.key, required this.tipo}) : _tinted = false;

  const TipoChip.tinted({super.key, required this.tipo}) : _tinted = true;

  final TipoPonto tipo;
  final bool _tinted;

  @override
  Widget build(BuildContext context) {
    final cor = TipoVisuals.corDe(tipo);

    if (_tinted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.15),
          border: Border.all(color: cor.withValues(alpha: 0.4)),
          borderRadius: AppRadius.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TipoVisuals.iconeDe(tipo), size: 16, color: cor),
            const SizedBox(width: 6),
            Text(tipo.label, style: TextStyle(color: cor, fontSize: 13)),
          ],
        ),
      );
    }

    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tipo.label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          letterSpacing: 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
