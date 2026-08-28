import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/onboarding_etapa.dart';

class OnboardingBarraProgresso extends StatelessWidget {
  const OnboardingBarraProgresso({super.key, required this.etapaAtual});

  final OnboardingEtapa etapaAtual;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final etapas = OnboardingEtapa.values;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        children: [
          for (var i = 0; i < etapas.length; i++) ...[
            _CirculoEtapa(
              numero: etapas[i].numeroExibicao,
              preenchido: i <= etapaAtual.index,
              colors: colors,
            ),
            if (i < etapas.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  color: i < etapaAtual.index ? colors.primary : colors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CirculoEtapa extends StatelessWidget {
  const _CirculoEtapa({
    required this.numero,
    required this.preenchido,
    required this.colors,
  });

  final int numero;
  final bool preenchido;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: preenchido ? colors.primary : colors.surfaceVariant,
      ),
      child: Text(
        '$numero',
        style: TextStyle(
          color: preenchido ? Colors.white : colors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
