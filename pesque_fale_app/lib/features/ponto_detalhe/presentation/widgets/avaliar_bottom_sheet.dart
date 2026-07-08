import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../pesquisa/domain/ponto.dart';
import '../../data/avaliacoes_repository.dart';
import '../../domain/avaliacao.dart';
import '../../providers/avaliar_provider.dart';
import '../../providers/ponto_detalhe_provider.dart';
import 'nota_selector.dart';

class AvaliarBottomSheet {
  AvaliarBottomSheet._();

  static void show(
    BuildContext context, {
    required Ponto ponto,
    Avaliacao? existente,
  }) {
    final detalheProvider = context.read<PontoDetalheProvider>();
    final avaliacoesRepository = context.read<AvaliacoesRepository>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => ChangeNotifierProvider<AvaliarProvider>(
        create: (_) =>
            AvaliarProvider(repository: avaliacoesRepository)
              ..inicializar(existente: existente),
        child: _Conteudo(ponto: ponto, detalheProvider: detalheProvider),
      ),
    );
  }
}

class _Conteudo extends StatefulWidget {
  const _Conteudo({required this.ponto, required this.detalheProvider});

  final Ponto ponto;
  final PontoDetalheProvider detalheProvider;

  @override
  State<_Conteudo> createState() => _ConteudoState();
}

class _ConteudoState extends State<_Conteudo> {
  late final TextEditingController _comentarioController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AvaliarProvider>();
    _comentarioController = TextEditingController(text: provider.comentario);
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<AvaliarProvider>();
    final salvando = provider.status == AvaliarStatus.salvando;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              provider.ehEdicao
                  ? 'Editar avaliação'
                  : 'Avaliar ${widget.ponto.nome}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            NotaSelector(nota: provider.nota, onChanged: provider.alterarNota),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _comentarioController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Como foi sua experiência? (opcional)',
                border: OutlineInputBorder(),
              ),
              onChanged: provider.alterarComentario,
            ),
            if (provider.mensagemErro != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                provider.mensagemErro!,
                style: TextStyle(color: colors.danger),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (provider.ehEdicao)
                  TextButton(
                    onPressed: salvando
                        ? null
                        : () => _excluir(context, provider),
                    style: TextButton.styleFrom(foregroundColor: colors.danger),
                    child: const Text('Excluir'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: salvando
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppSpacing.xs),
                ElevatedButton(
                  onPressed: provider.podeSalvar && !salvando
                      ? () => _salvar(context, provider)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvar(BuildContext context, AvaliarProvider provider) async {
    final resultado = await provider.salvar(widget.ponto.id);
    if (!context.mounted) return;

    if (resultado != null) {
      widget.detalheProvider.aplicarNovaAvaliacao(resultado);
      Navigator.of(context).pop();
      AppSnackbar.showSuccess(context, 'Avaliação salva');
    } else if (provider.mensagemErro != null) {
      AppSnackbar.showError(context, provider.mensagemErro!);
    }
  }

  Future<void> _excluir(BuildContext context, AvaliarProvider provider) async {
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

    final ok = await provider.deletar(widget.ponto.id);
    if (!context.mounted) return;

    if (ok) {
      widget.detalheProvider.removerMinhaAvaliacao();
      Navigator.of(context).pop();
      AppSnackbar.showSuccess(context, 'Avaliação excluída');
    } else if (provider.mensagemErro != null) {
      AppSnackbar.showError(context, provider.mensagemErro!);
    }
  }
}
