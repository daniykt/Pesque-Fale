import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/avaliacoes_repository.dart';
import '../providers/avaliacoes_lista_provider.dart';
import 'widgets/avaliacao_card.dart';
import 'widgets/skeletons/avaliacao_card_skeleton.dart';

class AvaliacoesPage extends StatelessWidget {
  const AvaliacoesPage({super.key, required this.pontoId});

  final String pontoId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AvaliacoesListaProvider>(
      create: (ctx) => AvaliacoesListaProvider(
        repository: ctx.read<AvaliacoesRepository>(),
        pontoId: pontoId,
      )..carregar(),
      child: const _AvaliacoesView(),
    );
  }
}

class _AvaliacoesView extends StatefulWidget {
  const _AvaliacoesView();

  @override
  State<_AvaliacoesView> createState() => _AvaliacoesViewState();
}

class _AvaliacoesViewState extends State<_AvaliacoesView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AvaliacoesListaProvider>().carregarMais();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<AvaliacoesListaProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Avaliações')),
      body: switch (provider.status) {
        AvaliacoesListaStatus.carregando => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, _) => const AvaliacaoCardSkeleton(),
        ),
        AvaliacoesListaStatus.erro => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.danger),
                const SizedBox(height: AppSpacing.sm),
                Text(provider.mensagemErro ?? 'Não foi possível carregar'),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  onPressed: provider.carregar,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        AvaliacoesListaStatus.sucesso || AvaliacoesListaStatus.carregandoMais =>
          provider.avaliacoes.isEmpty
              ? Center(
                  child: Text(
                    'Seja o primeiro a avaliar este ponto',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount:
                      provider.avaliacoes.length +
                      (provider.status == AvaliacoesListaStatus.carregandoMais
                          ? 1
                          : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index >= provider.avaliacoes.length) {
                      return const AvaliacaoCardSkeleton();
                    }
                    return AvaliacaoCard(avaliacao: provider.avaliacoes[index]);
                  },
                ),
      },
    );
  }
}
