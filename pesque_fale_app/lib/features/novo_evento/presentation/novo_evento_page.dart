import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/confirmacao_sheet.dart';
import '../../nova_publicacao/presentation/widgets/campo_descricao.dart';
import '../../nova_publicacao/presentation/widgets/campo_foto.dart';
import '../../nova_publicacao/presentation/widgets/selecao_ponto_bottom_sheet.dart';
import '../providers/novo_evento_provider.dart';
import 'widgets/campo_data_hora.dart';
import 'widgets/campo_local_evento.dart';

class NovoEventoPage extends StatelessWidget {
  const NovoEventoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NovoEventoProvider>();

    return PopScope(
      canPop: !provider.enviando && !provider.formularioSujo,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || provider.enviando) return;
        final descartar = await _confirmarDescartar(context);
        if (descartar && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(provider.editando ? 'Editar evento' : 'Novo evento'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Rotulo(texto: 'Título', obrigatorio: true),
              TextFormField(
                initialValue: provider.titulo,
                onChanged: provider.setTitulo,
                maxLength: NovoEventoProvider.limiteTitulo,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ex.: Torneio de pesca do Lago Azul',
                  errorText: provider.erroDe('titulo'),
                  errorMaxLines: 2,
                  border: OutlineInputBorder(borderRadius: AppRadius.mdRadius),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _Rotulo(texto: 'Início', obrigatorio: true),
              CampoDataHora(
                key: const ValueKey('campo-inicio'),
                valor: provider.dataInicio,
                vazio: 'Toque para escolher a data e a hora',
                erro: provider.erroDe('dataInicio'),
                onEscolher: () => _escolherInicio(context, provider),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _Rotulo(texto: 'Fim (opcional)'),
              CampoDataHora(
                key: const ValueKey('campo-fim'),
                valor: provider.dataFim,
                vazio: 'Toque para escolher quando termina',
                erro: provider.erroDe('dataFim'),
                onEscolher: () => _escolherFim(context, provider),
                onLimpar: () => provider.setDataFim(null),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _Rotulo(texto: 'Local (opcional)'),
              CampoLocalEvento(
                ponto: provider.ponto,
                localTexto: provider.localTexto,
                limite: NovoEventoProvider.limiteLocal,
                erro: provider.erroDe('localTexto'),
                onEscolherPonto: () => _escolherPonto(context, provider),
                onRemoverPonto: () => provider.setPonto(null),
                onLocalTexto: provider.setLocalTexto,
              ),
              const SizedBox(height: AppSpacing.md),
              CampoDescricao(
                valor: provider.descricao,
                onChanged: provider.setDescricao,
                limite: NovoEventoProvider.limiteDescricao,
                dica: 'Conte como vai ser o evento, regras, premiação...',
              ),
              const SizedBox(height: AppSpacing.md),
              const _Rotulo(texto: 'Foto (opcional)'),
              CampoFoto(
                foto: provider.fotoBytes,
                fotoUrl: provider.imagemUrlAtual,
                onEscolher: () => _escolherFoto(provider),
                onRemover: provider.removerFoto,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: provider.enviando
                      ? null
                      : () => _salvar(context, provider),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdRadius,
                    ),
                  ),
                  child: provider.enviando
                      ? const _Enviando()
                      : Text(
                          provider.editando
                              ? 'Salvar alterações'
                              : 'Criar evento',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _escolherInicio(
    BuildContext context,
    NovoEventoProvider provider,
  ) async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final atual = provider.dataInicio;
    final escolhido = await _escolherDataHora(
      context,
      sugestao: atual ?? DateTime(agora.year, agora.month, agora.day + 1, 7),
      primeiroDia: atual != null && atual.isBefore(hoje)
          ? DateTime(atual.year, atual.month, atual.day)
          : hoje,
      titulo: 'Quando começa?',
    );
    if (escolhido != null) provider.setDataInicio(escolhido);
  }

  Future<void> _escolherFim(
    BuildContext context,
    NovoEventoProvider provider,
  ) async {
    final agora = DateTime.now();
    final inicio = provider.dataInicio;
    final base = inicio ?? agora;
    final escolhido = await _escolherDataHora(
      context,
      sugestao: provider.dataFim ?? base.add(const Duration(hours: 4)),
      primeiroDia: DateTime(base.year, base.month, base.day),
      titulo: 'Quando termina?',
    );
    if (escolhido != null) provider.setDataFim(escolhido);
  }

  Future<DateTime?> _escolherDataHora(
    BuildContext context, {
    required DateTime sugestao,
    required DateTime primeiroDia,
    required String titulo,
  }) async {
    final ultimoDia = DateTime(primeiroDia.year + 3, 12, 31);
    final inicial = sugestao.isBefore(primeiroDia) ? primeiroDia : sugestao;
    final dia = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primeiroDia,
      lastDate: ultimoDia,
      helpText: titulo,
    );
    if (dia == null || !context.mounted) return null;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(inicial),
      helpText: 'Que horas?',
    );
    if (hora == null) return null;
    return DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute);
  }

  Future<void> _escolherPonto(
    BuildContext context,
    NovoEventoProvider provider,
  ) async {
    final ponto = await SelecaoPontoBottomSheet.show(context);
    if (ponto != null) provider.setPonto(PontoDoEvento.dePonto(ponto));
  }

  Future<void> _escolherFoto(NovoEventoProvider provider) async {
    final arquivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();
    provider.setFoto(
      bytes: bytes,
      filename: arquivo.name,
      mimeType: arquivo.mimeType ?? 'image/jpeg',
    );
  }

  Future<void> _salvar(
    BuildContext context,
    NovoEventoProvider provider,
  ) async {
    final evento = await provider.enviar();
    if (!context.mounted) return;
    if (evento != null) {
      final mensagem = provider.editando
          ? 'Evento atualizado!'
          : 'Evento criado!';
      Navigator.of(context).pop(evento);
      AppSnackbar.showSuccess(context, mensagem);
    } else if (provider.mensagemErro != null) {
      AppSnackbar.showError(context, provider.mensagemErro!);
    }
  }

  Future<bool> _confirmarDescartar(BuildContext context) {
    final editando = context.read<NovoEventoProvider>().editando;
    return ConfirmacaoSheet.show(
      context,
      titulo: editando ? 'Descartar as alterações?' : 'Descartar o evento?',
      mensagem: 'As informações preenchidas serão perdidas.',
      confirmar: 'Descartar',
      iconeConfirmar: Icons.delete_outline,
      cancelar: 'Continuar editando',
    );
  }
}

class _Enviando extends StatelessWidget {
  const _Enviando();

  @override
  Widget build(BuildContext context) {
    final cor = IconTheme.of(context).color;
    return Semantics(
      label: 'Salvando o evento',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: cor),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text('Salvando...'),
        ],
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo({required this.texto, this.obrigatorio = false});

  final String texto;
  final bool obrigatorio;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text.rich(
        TextSpan(
          text: texto,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          children: [
            if (obrigatorio)
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
