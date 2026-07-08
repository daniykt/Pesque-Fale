import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/tipo_chip.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../ponto_detalhe/data/avaliacoes_repository.dart';
import '../../../ponto_detalhe/domain/avaliacao.dart';
import '../../../ponto_detalhe/presentation/widgets/avaliar_bottom_sheet.dart';
import '../../domain/ponto.dart';
import '../../providers/pesquisa_locais_provider.dart';

class PontoDetailsSheet {
  PontoDetailsSheet._();

  static void show(BuildContext context, Ponto ponto) {
    final rootContext = context;

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
        builder: (context, scrollController) => _Conteudo(
          ponto: ponto,
          scrollController: scrollController,
          rootContext: rootContext,
        ),
      ),
    );
  }
}

class _Conteudo extends StatefulWidget {
  const _Conteudo({
    required this.ponto,
    required this.scrollController,
    required this.rootContext,
  });

  final Ponto ponto;
  final ScrollController scrollController;
  final BuildContext rootContext;

  @override
  State<_Conteudo> createState() => _ConteudoState();
}

class _ConteudoState extends State<_Conteudo> {
  bool _carregandoMinha = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final ponto = widget.ponto;
    final temFoto = ponto.fotoCapa != null && ponto.fotoCapa!.isNotEmpty;

    return ListView(
      controller: widget.scrollController,
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
                  TipoChip.tinted(tipo: ponto.tipo),
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
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/pontos',
                        arguments: ponto.id,
                      ),
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
                      onPressed: _carregandoMinha ? null : _avaliar,
                      child: _carregandoMinha
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Avaliar'),
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

  Future<void> _avaliar() async {
    final logado = context.read<AuthProvider>().usuario != null;
    if (!logado) {
      AppSnackbar.showInfo(context, 'Faça login para avaliar');
      return;
    }

    setState(() => _carregandoMinha = true);

    final navigator = Navigator.of(context);
    final avaliacoesRepository = context.read<AvaliacoesRepository>();
    final locaisProvider = Provider.of<PesquisaLocaisProvider>(
      widget.rootContext,
      listen: false,
    );
    final rootContext = widget.rootContext;

    Avaliacao? minha;
    try {
      minha = await avaliacoesRepository.minhaAvaliacao(widget.ponto.id);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        'Não foi possível verificar sua avaliação',
      );
      setState(() => _carregandoMinha = false);
      return;
    }

    if (!mounted || !rootContext.mounted) return;

    navigator.pop();
    AvaliarBottomSheet.show(
      rootContext,
      ponto: widget.ponto,
      existente: minha,
      onSaved: (_) => locaisProvider.recarregar(),
      onDeleted: () => locaisProvider.recarregar(),
    );
  }
}
