import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/tour_passo.dart';

/// Card modal central do tour guiado. Widget puro — não conhece o
/// [TourProvider], apenas recebe o passo atual e dispara callbacks.
class TourCard extends StatelessWidget {
  const TourCard({
    super.key,
    required this.passo,
    required this.total,
    required this.onAnterior,
    required this.onProximo,
    required this.onPular,
  });

  final TourPasso passo;
  final int total;
  final VoidCallback onAnterior;
  final VoidCallback onProximo;
  final VoidCallback onPular;

  bool get _ultimoPasso => passo.index >= total - 1;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final progresso = (passo.index + 1) / total;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 400,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.lgRadius,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      'Tour guiado',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onPular,
                    child: const Text('Pular'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Passo ${passo.index + 1} de $total',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    '${(progresso * 100).round()}%',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              ClipRRect(
                borderRadius: AppRadius.pillRadius,
                child: LinearProgressIndicator(
                  value: progresso,
                  minHeight: 6,
                  backgroundColor: colors.surfaceVariant,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                passo.titulo,
                style: textTheme.headlineMedium?.copyWith(
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                passo.descricao,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(total, (i) {
                  final ativo = i == passo.index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxs / 2,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: ativo ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ativo ? colors.primary : colors.border,
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: passo.index == 0 ? null : onAnterior,
                  child: const Text('Anterior'),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onProximo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.lgRadius,
                    ),
                  ),
                  child: Text(_ultimoPasso ? 'Começar! 🎣' : 'Próximo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
