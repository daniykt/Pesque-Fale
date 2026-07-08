import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/avaliacao_min_filtro.dart';
import '../../domain/tipo_ponto.dart';
import '../../providers/pesquisa_locais_provider.dart';
import '../widgets/busca_bar.dart';
import '../widgets/dropdown_filtro.dart';
import '../widgets/locais_lista_view.dart';
import '../widgets/locais_mapa_view.dart';
import '../widgets/modo_toggle.dart';

class LocaisTab extends StatelessWidget {
  const LocaisTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PesquisaLocaisProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: Column(
            children: [
              BuscaBar(
                hintText: 'Buscar rios, lagos...',
                onChanged: provider.alterarBusca,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: DropdownFiltro<TipoPonto?>(
                      titulo: 'Tipo',
                      valor: provider.filtros.tipo,
                      itens: const [null, ...TipoPonto.values],
                      labelDe: (t) => t?.label ?? 'Todos',
                      onChanged: provider.alterarTipo,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownFiltro<AvaliacaoMinFiltro>(
                      titulo: 'Avaliação Mínima',
                      valor: provider.filtros.avaliacaoMin,
                      itens: AvaliacaoMinFiltro.values,
                      labelDe: (a) => a.label,
                      onChanged: provider.alterarAvaliacaoMin,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: ModoToggle(
                  modo: provider.modo,
                  onChanged: (novo) async {
                    await provider.alterarModo(novo);
                    if (provider.localizacaoNegada && context.mounted) {
                      AppSnackbar.showWarning(
                        context,
                        'Ative a localização para usar o mapa',
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
        Expanded(
          child: provider.modo == ModoLocais.lista
              ? const LocaisListaView()
              : const LocaisMapaView(),
        ),
      ],
    );
  }
}
