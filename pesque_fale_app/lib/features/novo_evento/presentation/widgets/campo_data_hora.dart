import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/data_hora_por_extenso.dart';

class CampoDataHora extends StatelessWidget {
  const CampoDataHora({
    super.key,
    required this.valor,
    required this.vazio,
    required this.onEscolher,
    this.onLimpar,
    this.erro,
  });

  final DateTime? valor;
  final String vazio;
  final VoidCallback onEscolher;
  final VoidCallback? onLimpar;
  final String? erro;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textos = Theme.of(context).textTheme;
    final valor = this.valor;
    final erro = this.erro;
    final corBorda = erro != null ? colors.danger : colors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onEscolher,
          borderRadius: AppRadius.mdRadius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: corBorda),
              borderRadius: AppRadius.mdRadius,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  color: valor != null
                      ? colors.primaryAccent
                      : colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    valor != null ? dataHoraPorExtenso(valor) : vazio,
                    style: textos.bodyLarge?.copyWith(
                      color: valor != null
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ),
                if (valor != null && onLimpar != null)
                  IconButton(
                    onPressed: onLimpar,
                    tooltip: 'Remover',
                    icon: Icon(Icons.close, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
        if (erro != null)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xxs,
              left: AppSpacing.sm,
            ),
            child: Text(
              erro,
              style: textos.bodySmall?.copyWith(color: colors.danger),
            ),
          ),
      ],
    );
  }
}
