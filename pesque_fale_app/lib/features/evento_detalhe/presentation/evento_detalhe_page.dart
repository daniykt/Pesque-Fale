import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/router/navegacao_perfil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/cloudinary_url.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/confirmacao_sheet.dart';
import '../../../shared/widgets/imagem_placeholder.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/domain/evento.dart';
import '../../novo_evento/domain/data_hora_por_extenso.dart';
import '../providers/evento_detalhe_provider.dart';

class EventoDetalhePage extends StatefulWidget {
  const EventoDetalhePage({super.key, this.agora});

  final DateTime Function()? agora;

  @override
  State<EventoDetalhePage> createState() => _EventoDetalhePageState();
}

class _EventoDetalhePageState extends State<EventoDetalhePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EventoDetalheProvider>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventoDetalheProvider>();
    final usuarioId = context.watch<AuthProvider>().usuario?.id;
    final evento = provider.evento;

    return Scaffold(
      appBar: AppBar(title: const Text('Evento')),
      body: switch (provider.status) {
        StatusEventoDetalhe.carregando => const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Carregando o evento',
          ),
        ),
        StatusEventoDetalhe.naoEncontrado => _Aviso(
          icone: Icons.event_busy,
          mensagem: 'Este evento não existe mais.',
          rotuloBotao: 'Voltar',
          onBotao: () => Navigator.of(context).pop(),
        ),
        StatusEventoDetalhe.erro => _Aviso(
          icone: Icons.cloud_off,
          mensagem:
              provider.mensagemErro ?? 'Não foi possível carregar o evento.',
          rotuloBotao: 'Tentar de novo',
          onBotao: provider.carregar,
        ),
        StatusEventoDetalhe.carregado when evento != null => _Conteudo(
          evento: evento,
          agora: (widget.agora ?? DateTime.now)(),
          ehOrganizador: provider.ehOrganizador(usuarioId),
          excluindo: provider.excluindo,
          onEditar: () => _editar(context, evento),
          onExcluir: () => _excluir(context),
        ),
        StatusEventoDetalhe.carregado => const SizedBox.shrink(),
      },
    );
  }

  Future<void> _editar(BuildContext context, Evento evento) async {
    final provider = context.read<EventoDetalheProvider>();
    final editado = await Navigator.of(
      context,
    ).pushNamed<Evento>('/evento/editar', arguments: evento);
    if (editado != null) provider.atualizar(editado);
  }

  Future<void> _excluir(BuildContext context) async {
    final provider = context.read<EventoDetalheProvider>();
    final confirmou = await ConfirmacaoSheet.show(
      context,
      titulo: 'Excluir o evento?',
      mensagem:
          'O evento sai da lista para todo mundo. Isso não pode ser desfeito.',
      confirmar: 'Excluir evento',
      iconeConfirmar: Icons.delete_outline,
      cancelar: 'Cancelar',
    );
    if (!confirmou || !context.mounted) return;
    final excluiu = await provider.excluir();
    if (!context.mounted) return;
    if (excluiu) {
      Navigator.of(context).pop(true);
      AppSnackbar.showSuccess(context, 'Evento excluído.');
    } else {
      AppSnackbar.showError(
        context,
        provider.mensagemErro ?? 'Não foi possível excluir o evento.',
      );
    }
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({
    required this.evento,
    required this.agora,
    required this.ehOrganizador,
    required this.excluindo,
    required this.onEditar,
    required this.onExcluir,
  });

  final Evento evento;
  final DateTime agora;
  final bool ehOrganizador;
  final bool excluindo;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textos = Theme.of(context).textTheme;
    final fim = evento.dataFim;
    final descricao = evento.descricao?.trim() ?? '';
    final local = evento.localTexto?.trim() ?? '';
    final pontoId = evento.pontoId;
    final acontecendo =
        !evento.dataInicio.isAfter(agora) &&
        !(evento.dataFim ?? evento.dataInicio).isBefore(agora);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Capa(imagemUrl: evento.imagemUrl),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (acontecendo) ...[
                  const _Selo(texto: 'Acontecendo agora'),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(
                  evento.titulo,
                  style: textos.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _Linha(
                  icone: Icons.event,
                  rotulo: 'Começa',
                  texto: dataHoraPorExtenso(evento.dataInicio),
                ),
                if (fim != null)
                  _Linha(
                    icone: Icons.event_available,
                    rotulo: 'Termina',
                    texto: dataHoraPorExtenso(fim),
                  ),
                _Linha(
                  icone: Icons.location_on_outlined,
                  rotulo: 'Local',
                  texto: local.isEmpty ? 'Não informado' : local,
                  dicaToque: 'Abrir o ponto',
                  onTap: pontoId == null
                      ? null
                      : () => Navigator.of(
                          context,
                        ).pushNamed('/pontos', arguments: pontoId),
                ),
                const SizedBox(height: AppSpacing.xs),
                _Organizador(
                  evento: evento,
                  ehVoce: ehOrganizador,
                  onTap: evento.organizadorId.isEmpty
                      ? null
                      : () => abrirPerfil(context, evento.organizadorId),
                ),
                if (descricao.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Sobre o evento',
                    style: textos.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    descricao,
                    style: textos.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
                if (ehOrganizador) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _AcoesDoOrganizador(
                    excluindo: excluindo,
                    onEditar: onEditar,
                    onExcluir: onExcluir,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Capa extends StatelessWidget {
  const _Capa({required this.imagemUrl});

  final String? imagemUrl;

  @override
  Widget build(BuildContext context) {
    final url = imagemUrl;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: url != null && url.isNotEmpty
          ? Image.network(
              CloudinaryUrl.otimizar(url, largura: 1200, altura: 675),
              fit: BoxFit.cover,
              semanticLabel: 'Foto do evento',
              loadingBuilder: (context, child, progresso) =>
                  progresso == null ? child : const ImagemCarregando(),
              errorBuilder: (_, _, _) => const ImagemIndisponivel(),
            )
          : const ImagemIndisponivel(
              icone: Icons.event,
              tamanhoIcone: 64,
              mostrarTexto: false,
            ),
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final cor = colors.success;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: cor),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: cor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.icone,
    required this.rotulo,
    required this.texto,
    this.dicaToque,
    this.onTap,
  });

  final IconData icone;
  final String rotulo;
  final String texto;
  final String? dicaToque;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textos = Theme.of(context).textTheme;

    final linha = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, color: colors.primaryAccent),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rotulo,
                style: textos.labelLarge?.copyWith(color: colors.textSecondary),
              ),
              Text(
                texto,
                style: textos.bodyLarge?.copyWith(
                  color: onTap != null
                      ? colors.primaryAccent
                      : colors.textPrimary,
                  fontWeight: onTap != null ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(Icons.chevron_right, color: colors.textSecondary),
      ],
    );

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: linha,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        hint: dicaToque,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: linha,
            ),
          ),
        ),
      ),
    );
  }
}

class _Organizador extends StatelessWidget {
  const _Organizador({required this.evento, required this.ehVoce, this.onTap});

  final Evento evento;
  final bool ehVoce;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textos = Theme.of(context).textTheme;
    final foto = evento.organizadorFoto;
    final username = evento.organizadorUsername;
    final nome = evento.organizadorNome.isEmpty
        ? 'Organizador'
        : evento.organizadorNome;

    final linha = Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: colors.surfaceVariant,
          backgroundImage: foto != null ? NetworkImage(foto) : null,
          child: foto == null
              ? Icon(Icons.person, color: colors.textSecondary)
              : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ehVoce ? 'Organizado por você' : 'Organizado por',
                style: textos.labelLarge?.copyWith(color: colors.textSecondary),
              ),
              Text(
                nome,
                style: textos.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              if (username != null && username.isNotEmpty)
                Text(
                  '@$username',
                  style: textos.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(Icons.chevron_right, color: colors.textSecondary),
      ],
    );

    if (onTap == null) return linha;
    return Semantics(
      button: true,
      hint: 'Abrir o perfil',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: linha,
          ),
        ),
      ),
    );
  }
}

class _AcoesDoOrganizador extends StatelessWidget {
  const _AcoesDoOrganizador({
    required this.excluindo,
    required this.onEditar,
    required this.onExcluir,
  });

  final bool excluindo;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final forma = RoundedRectangleBorder(borderRadius: AppRadius.mdRadius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: excluindo ? null : onEditar,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar evento'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: forma,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: excluindo ? null : onExcluir,
          icon: excluindo
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colors.danger,
                  ),
                )
              : Icon(Icons.delete_outline, color: colors.danger),
          label: Text(
            excluindo ? 'Excluindo...' : 'Excluir evento',
            style: TextStyle(color: colors.danger),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: BorderSide(color: colors.danger),
            shape: forma,
          ),
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icone,
    required this.mensagem,
    required this.rotuloBotao,
    required this.onBotao,
  });

  final IconData icone;
  final String mensagem;
  final String rotuloBotao;
  final VoidCallback onBotao;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textos = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: colors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: textos.bodyLarge?.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onBotao,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(160, 48),
                foregroundColor: colors.primaryAccent,
                side: BorderSide(color: colors.primaryAccent),
              ),
              child: Text(rotuloBotao),
            ),
          ],
        ),
      ),
    );
  }
}
