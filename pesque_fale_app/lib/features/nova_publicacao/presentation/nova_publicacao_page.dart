import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../pesquisa/domain/ponto.dart';
import '../../pesquisa/presentation/seletor_ponto_page.dart';
import '../providers/nova_publicacao_provider.dart';
import 'widgets/botao_publicar.dart';
import 'widgets/campo_avaliacao.dart';
import 'widgets/campo_descricao.dart';
import 'widgets/campo_foto.dart';
import 'widgets/campo_local.dart';
import 'widgets/campo_tags.dart';

class NovaPublicacaoPage extends StatelessWidget {
  const NovaPublicacaoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NovaPublicacaoProvider>();

    return PopScope(
      canPop: !provider.formularioSujo,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final descartar = await _confirmarDescartar(context);
        if (descartar == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Nova Publicação')),
        body: Consumer<NovaPublicacaoProvider>(
          builder: (context, provider, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _LabelObrigatorio(texto: 'Foto'),
                CampoFoto(
                  foto: provider.foto,
                  onEscolher: () => _escolherFoto(context, provider),
                  onRemover: () => provider.setFoto(null),
                ),
                const SizedBox(height: 24),
                const _LabelObrigatorio(texto: 'Local'),
                CampoLocal(
                  ponto: provider.pontoSelecionado,
                  onSelecionar: () => _selecionarPonto(context, provider),
                ),
                const SizedBox(height: 24),
                CampoDescricao(
                  valor: provider.descricao,
                  onChanged: provider.setDescricao,
                  limite: NovaPublicacaoProvider.limiteMaximoDescricao,
                ),
                const SizedBox(height: 24),
                CampoAvaliacao(
                  nota: provider.avaliacaoNota,
                  onChanged: provider.setAvaliacao,
                ),
                const SizedBox(height: 24),
                CampoTags(
                  selecionadas: provider.tagsSelecionadas,
                  limite: NovaPublicacaoProvider.limiteMaximoTags,
                  onAdicionar: (tag) {
                    final ok = provider.adicionarTag(tag);
                    if (!ok &&
                        provider.tagsSelecionadas.length >=
                            NovaPublicacaoProvider.limiteMaximoTags) {
                      AppSnackbar.showInfo(
                        context,
                        'Limite de 5 tags atingido',
                      );
                    }
                  },
                  onRemover: provider.removerTag,
                ),
                const SizedBox(height: 32),
                BotaoPublicar(
                  habilitado: provider.podePublicar,
                  enviando: provider.status == StatusPublicacao.enviando,
                  onPressed: () => _publicar(context, provider),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _escolherFoto(
    BuildContext context,
    NovaPublicacaoProvider provider,
  ) async {
    final picker = ImagePicker();
    final XFile? arquivo = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (arquivo != null) provider.setFoto(File(arquivo.path));
  }

  Future<void> _selecionarPonto(
    BuildContext context,
    NovaPublicacaoProvider provider,
  ) async {
    final ponto = await Navigator.of(
      context,
    ).push<Ponto>(MaterialPageRoute(builder: (_) => const SeletorPontoPage()));
    if (ponto != null) provider.setPonto(ponto);
  }

  Future<void> _publicar(
    BuildContext context,
    NovaPublicacaoProvider provider,
  ) async {
    final publicacao = await provider.publicar();
    if (!context.mounted) return;
    if (publicacao != null) {
      Navigator.of(context).pop();
      AppSnackbar.showSuccess(context, 'Publicação enviada!');
    } else if (provider.mensagemErro != null) {
      AppSnackbar.showError(context, provider.mensagemErro!);
    }
  }

  Future<bool?> _confirmarDescartar(BuildContext context) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Descartar publicação?'),
        content: const Text('As informações preenchidas serão perdidas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Descartar', style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );
  }
}

class _LabelObrigatorio extends StatelessWidget {
  const _LabelObrigatorio({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: texto,
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          children: [
            TextSpan(
              text: ' *',
              style: TextStyle(color: colors.danger),
            ),
          ],
        ),
      ),
    );
  }
}
