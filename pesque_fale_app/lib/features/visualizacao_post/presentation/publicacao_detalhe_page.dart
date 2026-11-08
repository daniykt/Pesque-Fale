import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/cloudinary_url.dart';
import '../../../core/utils/tempo_relativo.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/estrelas_readonly.dart';
import '../../../shared/widgets/badge_equipe/badge_nome_usuario.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/data/comentarios_repository.dart';
import '../../feed/domain/publicacao.dart';
import '../../feed/presentation/widgets/acoes_bar.dart';
import '../../feed/presentation/widgets/comentario_input_bar.dart';
import '../../feed/presentation/widgets/comentarios_lista.dart';
import '../../feed/presentation/widgets/publicacao_menu_sheet.dart';
import '../../feed/providers/comentarios_provider.dart';
import '../providers/publicacao_detalhe_provider.dart';
import 'widgets/foto_publicacao.dart';

/// Ícones da barra de status sobre a barra superior em `surface`: escuros no
/// tema claro, claros no escuro.
@visibleForTesting
SystemUiOverlayStyle estiloBarraDeStatus(Brightness brilhoDoTema) {
  final base = brilhoDoTema == Brightness.dark
      ? SystemUiOverlayStyle.light
      : SystemUiOverlayStyle.dark;
  // Só a barra de status, como o AppBar faz por padrão: a barra de navegação
  // do sistema fica como está.
  return SystemUiOverlayStyle(
    statusBarBrightness: base.statusBarBrightness,
    statusBarIconBrightness: base.statusBarIconBrightness,
  );
}

class PublicacaoDetalhePage extends StatefulWidget {
  const PublicacaoDetalhePage({super.key});

  @override
  State<PublicacaoDetalhePage> createState() => _PublicacaoDetalhePageState();
}

class _PublicacaoDetalhePageState extends State<PublicacaoDetalhePage> {
  final _scrollController = ScrollController();
  final _comentarioFocusNode = FocusNode();
  bool _saindo = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _comentarioFocusNode.dispose();
    super.dispose();
  }

  void _onComentarTap() {
    _comentarioFocusNode.requestFocus();
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _sairSeRemovida(PublicacaoDetalheProvider provider) {
    if (provider.status != StatusDetalhe.removida || _saindo) return;
    _saindo = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!provider.excluidaAqui) {
        AppSnackbar.showInfo(context, 'Esta publicação foi excluída.');
      }
      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicacaoDetalheProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    _sairSeRemovida(provider);

    final tema = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      // Barra clara: o menu ⋯ fica na linha do autor, não aqui.
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.primaryAccent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: estiloBarraDeStatus(tema.brightness),
        shape: Border(bottom: BorderSide(color: colors.border)),
        title: Text(
          'Publicação',
          style: tema.textTheme.titleMedium?.copyWith(
            color: colors.primaryAccent,
          ),
        ),
      ),
      body: switch (provider.status) {
        StatusDetalhe.carregando => const Center(
          child: CircularProgressIndicator(),
        ),
        StatusDetalhe.erro => _ErroView(
          mensagem: provider.mensagemErro,
          onTentarNovamente: provider.carregar,
          colors: colors,
        ),
        StatusDetalhe.carregado => _ConteudoDetalhe(
          publicacao: provider.publicacao!,
          scrollController: _scrollController,
          comentarioFocusNode: _comentarioFocusNode,
          onComentarTap: _onComentarTap,
        ),
        StatusDetalhe.removida => const SizedBox.shrink(),
      },
    );
  }
}

class _ErroView extends StatelessWidget {
  const _ErroView({
    required this.mensagem,
    required this.onTentarNovamente,
    required this.colors,
  });

  final String? mensagem;
  final VoidCallback onTentarNovamente;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.danger),
            const SizedBox(height: AppSpacing.sm),
            Text(mensagem ?? 'Não foi possível carregar'),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: onTentarNovamente,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConteudoDetalhe extends StatelessWidget {
  const _ConteudoDetalhe({
    required this.publicacao,
    required this.scrollController,
    required this.comentarioFocusNode,
    required this.onComentarTap,
  });

  final Publicacao publicacao;
  final ScrollController scrollController;
  final FocusNode comentarioFocusNode;
  final VoidCallback onComentarTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final comentariosRepo = context.read<ComentariosRepository>();
    final authProvider = context.read<AuthProvider>();
    final detalhe = context.read<PublicacaoDetalheProvider>();
    final temFoto =
        publicacao.imagemUrl != null && publicacao.imagemUrl!.trim().isNotEmpty;
    final temDescricao =
        publicacao.descricao != null && publicacao.descricao!.isNotEmpty;
    // Sem foto, o texto é o conteúdo principal e fica maior.
    final estiloTexto = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: colors.textPrimary,
      fontSize: temFoto ? 16 : 18,
    );

    return ChangeNotifierProvider<ComentariosProvider>(
      create: (_) => ComentariosProvider(
        repository: comentariosRepo,
        publicacaoId: publicacao.id,
        authProvider: authProvider,
        onCountChange: detalhe.aplicarDeltaComentarios,
      )..carregarInicial(),
      // O Builder dá um context abaixo do ComentariosProvider criado acima.
      // Com o context do _ConteudoDetalhe, a leitura no onNotification não
      // acha o provider e lança a cada rolagem, quebrando os toques (#318).
      child: Builder(
        builder: (context) => Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  final metrics = notification.metrics;
                  if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                    context.read<ComentariosProvider>().carregarMais();
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Ordem visual = ordem do leitor de tela: autor, texto,
                    // foto, ações, local e comentários.
                    children: [
                      _LinhaAutor(
                        publicacao: publicacao,
                        onMenu: () => PublicacaoMenuSheet.show(
                          context,
                          publicacao,
                          excluir: detalhe.excluir,
                        ),
                      ),
                      if (temDescricao)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.xs,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              publicacao.descricao!,
                              style: estiloTexto,
                            ),
                          ),
                        ),
                      if (publicacao.tags.isNotEmpty)
                        _TagsWrap(tags: publicacao.tags, colors: colors),
                      if (temFoto)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: FotoPublicacao(url: publicacao.imagemUrl!),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      AcoesBar(
                        publicacao: publicacao,
                        onComentarTap: onComentarTap,
                      ),
                      Divider(height: 1, color: colors.border),
                      if (publicacao.localTexto != null ||
                          publicacao.avaliacaoNota != null) ...[
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: _CardLocal(publicacao: publicacao),
                        ),
                        Divider(height: 1, color: colors.border),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: ComentariosLista(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: ComentarioInputBar(focusNode: comentarioFocusNode),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaAutor extends StatelessWidget {
  const _LinhaAutor({required this.publicacao, required this.onMenu});

  final Publicacao publicacao;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textos = Theme.of(context).textTheme;
    final p = publicacao;
    final foto = CloudinaryUrl.avatar(p.autorFoto, tamanho: 80);
    final tempo = TempoRelativo.formatar(p.criadoEm);
    final meta = p.autorUsername != null
        ? '@${p.autorUsername} · $tempo'
        : tempo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xxs,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Avatar, nome e meta num alvo só, que abre o perfil.
          Expanded(
            child: InkWell(
              key: const ValueKey('detalhe-autor'),
              borderRadius: AppRadius.mdRadius,
              onTap: () =>
                  Navigator.pushNamed(context, '/perfil', arguments: p.autorId),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: kMinInteractiveDimension,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxs),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colors.surfaceVariant,
                        backgroundImage: foto != null
                            ? NetworkImage(foto)
                            : null,
                        child: foto == null
                            ? Icon(Icons.person, color: colors.textSecondary)
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BadgeNomeUsuario(
                              userId: p.autorId,
                              nome: Text(
                                p.autorNome,
                                style: textos.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: colors.primaryAccent,
                                ),
                              ),
                            ),
                            Text(
                              meta,
                              style: textos.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: colors.textSecondary),
            tooltip: 'Mais opções',
            onPressed: onMenu,
          ),
        ],
      ),
    );
  }
}

/// Local da pescaria e a nota que o autor deu ao publicar. Abre o local
/// quando a publicação está ligada a um ponto.
class _CardLocal extends StatelessWidget {
  const _CardLocal({required this.publicacao});

  final Publicacao publicacao;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textos = Theme.of(context).textTheme;
    final local = publicacao.localTexto;
    final nota = publicacao.avaliacaoNota;
    final pontoId = publicacao.pontoId;
    final notaTexto = nota?.toStringAsFixed(1).replaceAll('.', ',');

    final rotulo = [
      if (local != null) 'Local: $local',
      if (notaTexto != null) 'Nota do pescador: $notaTexto de 5',
    ].join('. ');

    final conteudo = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            if (local != null) ...[
              Icon(Icons.location_on, color: colors.primaryAccent),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (local != null)
                    Text(
                      local,
                      style: textos.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  if (nota != null)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.xs,
                      children: [
                        EstrelasReadonly(nota: nota, tamanho: 18),
                        Text(
                          '$notaTexto · nota do pescador',
                          style: textos.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (pontoId != null)
              Icon(Icons.chevron_right, color: colors.textSecondary),
          ],
        ),
      ),
    );

    final VoidCallback? abrirLocal = pontoId == null
        ? null
        : () => Navigator.pushNamed(context, '/pontos', arguments: pontoId);

    // Um nó só para o leitor de tela, com a ação de abrir quando há ponto.
    return Semantics(
      container: true,
      button: abrirLocal != null,
      label: rotulo,
      onTap: abrirLocal,
      excludeSemantics: true,
      child: Material(
        key: const ValueKey('detalhe-card-local'),
        color: colors.surfaceVariant,
        borderRadius: AppRadius.mdRadius,
        clipBehavior: Clip.antiAlias,
        child: abrirLocal == null
            ? conteudo
            : InkWell(onTap: abrirLocal, child: conteudo),
      ),
    );
  }
}

class _TagsWrap extends StatelessWidget {
  const _TagsWrap({required this.tags, required this.colors});

  final List<String> tags;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final tag in tags)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primaryAccent.withValues(alpha: 0.15),
                borderRadius: AppRadius.pillRadius,
              ),
              child: Text(
                '#$tag',
                style: TextStyle(color: colors.primaryAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
