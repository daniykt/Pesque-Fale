import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/tipo_visuals.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/ponto.dart';

class PontoDetailsSheet {
  PontoDetailsSheet._();

  static void show(BuildContext context, Ponto ponto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) =>
            _Conteudo(ponto: ponto, scrollController: scrollController),
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.ponto, required this.scrollController});

  final Ponto ponto;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final temFoto = ponto.fotoCapa != null && ponto.fotoCapa!.isNotEmpty;
    final cor = TipoVisuals.corDe(ponto.tipo);

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      children: [
        if (temFoto)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              ponto.fotoCapa!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ponto.nome,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ponto.tipo.label.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text('${ponto.cidade}-${ponto.estado}'),
                  if (ponto.distanciaKm != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '• ${ponto.distanciaKm} km',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${ponto.avgNota.toStringAsFixed(1)} (${ponto.totalAvaliacoes} avaliações)',
                  ),
                ],
              ),
              if (ponto.descricao != null && ponto.descricao!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(ponto.descricao!),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          AppSnackbar.showInfo(context, 'Detalhes em breve'),
                      child: const Text('Ver detalhes'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          AppSnackbar.showInfo(context, 'Rotas em breve'),
                      child: const Text('Traçar rota'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
