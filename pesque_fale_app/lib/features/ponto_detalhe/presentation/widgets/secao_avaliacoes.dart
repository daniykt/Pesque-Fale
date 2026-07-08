import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../pesquisa/domain/ponto.dart';
import '../../data/avaliacoes_exceptions.dart';
import '../../data/avaliacoes_repository.dart';
import '../../providers/ponto_detalhe_provider.dart';
import '../avaliacoes_page.dart';
import 'avaliacao_card.dart';
import 'avaliar_bottom_sheet.dart';
import 'minha_avaliacao_card.dart';
import 'secao_titulo.dart';

class SecaoAvaliacoes extends StatelessWidget {
  const SecaoAvaliacoes({super.key, required this.ponto});

  final Ponto ponto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<PontoDetalheProvider>();
    final logado = context.watch<AuthProvider>().usuario != null;
    final minha = provider.minhaAvaliacao;
    final outras = provider.primeirasAvaliacoes
        .where((a) => minha == null || a.id != minha.id)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SecaoTitulo(
                  'AVALIAÇÕES · ${provider.totalAvaliacoes}',
                ),
              ),
              if (provider.totalAvaliacoes > 5)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AvaliacoesPage(pontoId: ponto.id),
                    ),
                  ),
                  child: const Text('Ver todas'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (minha != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: MinhaAvaliacaoCard(
                avaliacao: minha,
                onEditar: () => AvaliarBottomSheet.show(
                  context,
                  ponto: ponto,
                  existente: minha,
                ),
                onExcluir: () => _confirmarExclusao(context),
              ),
            )
          else if (logado)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Você já pescou aqui? Compartilhe sua experiência!',
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          AvaliarBottomSheet.show(context, ponto: ponto),
                      child: const Text('Avaliar'),
                    ),
                  ],
                ),
              ),
            ),
          if (provider.totalAvaliacoes == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: Text(
                  'Seja o primeiro a avaliar este ponto',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: outras.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) =>
                  AvaliacaoCard(avaliacao: outras[index]),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir avaliação'),
        content: const Text('Tem certeza que deseja excluir sua avaliação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmado != true || !context.mounted) return;

    final detalheProvider = context.read<PontoDetalheProvider>();
    final repository = context.read<AvaliacoesRepository>();

    try {
      await repository.deletar(ponto.id);
      detalheProvider.removerMinhaAvaliacao();
      if (context.mounted) {
        AppSnackbar.showSuccess(context, 'Avaliação excluída');
      }
    } on AvaliacoesException catch (e) {
      if (context.mounted) AppSnackbar.showError(context, e.message);
    }
  }
}
