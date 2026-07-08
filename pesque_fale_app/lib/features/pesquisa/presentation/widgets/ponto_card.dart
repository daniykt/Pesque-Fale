import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/tipo_chip.dart';
import '../../domain/ponto.dart';

class PontoCard extends StatelessWidget {
  const PontoCard({super.key, required this.ponto, required this.onTap});

  final Ponto ponto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final temFoto = ponto.fotoCapa != null && ponto.fotoCapa!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdRadius,
      child: ClipRRect(
        borderRadius: AppRadius.mdRadius,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: colors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: temFoto
                    ? Image.network(ponto.fotoCapa!, fit: BoxFit.cover)
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.primary, colors.primaryAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TipoChip.solid(tipo: ponto.tipo),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      ponto.nome,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: colors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        _Estrelas(nota: ponto.avgNota),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          ponto.avgNota.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '(${ponto.totalAvaliacoes} avaliações)',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ponto.cidade}-${ponto.estado}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Estrelas extends StatelessWidget {
  const _Estrelas({required this.nota});

  final double nota;

  @override
  Widget build(BuildContext context) {
    final cheias = nota.floor();
    final temMeia = (nota - cheias) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData icon;
        if (i < cheias) {
          icon = Icons.star;
        } else if (i == cheias && temMeia) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, size: 16, color: Colors.amber);
      }),
    );
  }
}
