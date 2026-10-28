import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/estado_centralizado_rolavel.dart';
import '../../providers/pesquisa_locais_provider.dart';
import 'ponto_card.dart';
import 'skeletons/ponto_card_skeleton.dart';

class LocaisListaView extends StatelessWidget {
  const LocaisListaView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<PesquisaLocaisProvider>();

    // Recarregando com pontos já na tela (ex.: voltando da tela do ponto):
    // mantém a lista, como o mapa já faz, em vez de piscar o skeleton.
    final status =
        provider.status == PesquisaLocaisStatus.carregando &&
            provider.pontos.isNotEmpty
        ? PesquisaLocaisStatus.sucesso
        : provider.status;

    switch (status) {
      case PesquisaLocaisStatus.idle:
      case PesquisaLocaisStatus.carregando:
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, _) => const PontoCardSkeleton(),
        );
      case PesquisaLocaisStatus.erro:
        return EstadoCentralizadoRolavel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.danger),
              const SizedBox(height: AppSpacing.sm),
              Text(provider.mensagemErro ?? 'Não foi possível buscar'),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: provider.recarregar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      case PesquisaLocaisStatus.vazio:
        return EstadoCentralizadoRolavel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: colors.textSecondary),
              const SizedBox(height: AppSpacing.sm),
              const Text('Nenhum local encontrado com esses filtros'),
            ],
          ),
        );
      case PesquisaLocaisStatus.sucesso:
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: provider.pontos.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final ponto = provider.pontos[index];
            return PontoCard(
              ponto: ponto,
              onTap: () async {
                await Navigator.pushNamed(
                  context,
                  '/pontos',
                  arguments: ponto.id,
                );
                if (!context.mounted) return;
                provider.recarregar();
              },
            );
          },
        );
    }
  }
}
