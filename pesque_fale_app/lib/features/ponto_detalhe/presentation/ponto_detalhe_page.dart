import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/ponto_detalhe_provider.dart';
import 'widgets/ponto_acoes_row.dart';
import 'widgets/ponto_capa_header.dart';
import 'widgets/ponto_header_info.dart';
import 'widgets/secao_avaliacoes.dart';
import 'widgets/secao_descricao.dart';
import 'widgets/secao_galeria.dart';
import 'widgets/secao_tags.dart';
import 'widgets/skeletons/ponto_detalhe_skeleton.dart';

class PontoDetalhePage extends StatefulWidget {
  const PontoDetalhePage({super.key, required this.pontoId});

  final String pontoId;

  @override
  State<PontoDetalhePage> createState() => _PontoDetalhePageState();
}

class _PontoDetalhePageState extends State<PontoDetalhePage> {
  @override
  void initState() {
    super.initState();
    context.read<PontoDetalheProvider>().carregar(widget.pontoId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PontoDetalheProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    switch (provider.status) {
      case PontoDetalheStatus.carregando:
        return const Scaffold(body: PontoDetalheSkeleton());
      case PontoDetalheStatus.erro:
        return Scaffold(
          appBar: AppBar(),
          body: Center(
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
                    onPressed: provider.recarregar,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        );
      case PontoDetalheStatus.sucesso:
        final ponto = provider.ponto!;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              PontoCapaHeader(ponto: ponto),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PontoHeaderInfo(ponto: ponto),
                    PontoAcoesRow(ponto: ponto),
                    SecaoDescricao(descricao: ponto.descricao),
                    SecaoTags(tags: ponto.tags),
                    SecaoGaleria(fotos: ponto.fotos),
                    SecaoAvaliacoes(ponto: ponto),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}
