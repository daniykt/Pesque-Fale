import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/cloudinary_url.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/estrelas_readonly.dart';
import '../../../shared/widgets/local_com_pin.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/data/comentarios_repository.dart';
import '../../feed/domain/publicacao.dart';
import '../../feed/presentation/widgets/acoes_bar.dart';
import '../../feed/presentation/widgets/comentario_input_bar.dart';
import '../../feed/presentation/widgets/comentarios_lista.dart';
import '../../feed/presentation/widgets/publicacao_menu_sheet.dart';
import '../../feed/providers/comentarios_provider.dart';
import '../../feed/providers/feed_provider.dart';
import '../providers/publicacao_detalhe_provider.dart';

class PublicacaoDetalhePage extends StatefulWidget {
  const PublicacaoDetalhePage({super.key});

  @override
  State<PublicacaoDetalhePage> createState() => _PublicacaoDetalhePageState();
}

class _PublicacaoDetalhePageState extends State<PublicacaoDetalhePage> {
  final _scrollController = ScrollController();
  final _comentarioFocusNode = FocusNode();

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicacaoDetalheProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actions: [
          if (provider.status == StatusDetalhe.carregado)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => PublicacaoMenuSheet.show(
                context,
                provider.publicacao!,
                onDeleted: () {
                  context.read<FeedProvider>().removerPublicacao(
                    provider.publicacao!.id,
                  );
                  Navigator.of(context).pop();
                },
              ),
            ),
        ],
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
    final feedProvider = context.read<FeedProvider>();

    return ChangeNotifierProvider<ComentariosProvider>(
      create: (_) => ComentariosProvider(
        repository: comentariosRepo,
        publicacaoId: publicacao.id,
        authProvider: authProvider,
        onCountChange: (delta) =>
            feedProvider.atualizarContadorComentarios(publicacao.id, delta),
      )..carregarInicial(),
      child: Column(
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
                  children: [
                    if (publicacao.imagemUrl != null)
                      _ImagemPost(imagemUrl: publicacao.imagemUrl!),
                    _HeaderAutor(publicacao: publicacao),
                    if (publicacao.localTexto != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: LocalComPin(
                          texto: publicacao.localTexto!,
                          onTap: publicacao.pontoId != null
                              ? () => Navigator.pushNamed(
                                  context,
                                  '/pontos',
                                  arguments: publicacao.pontoId,
                                )
                              : null,
                        ),
                      ),
                    if (publicacao.avaliacaoNota != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: EstrelasReadonly(
                          nota: publicacao.avaliacaoNota!,
                          tamanho: 28,
                        ),
                      ),
                    if (publicacao.descricao != null &&
                        publicacao.descricao!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Text(
                          publicacao.descricao!,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    if (publicacao.tags.isNotEmpty)
                      _TagsWrap(tags: publicacao.tags, colors: colors),
                    AcoesBar(
                      publicacao: publicacao,
                      onComentarTap: onComentarTap,
                    ),
                    Divider(height: 1, color: colors.border),
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
          ComentarioInputBar(focusNode: comentarioFocusNode),
        ],
      ),
    );
  }
}

class _ImagemPost extends StatelessWidget {
  const _ImagemPost({required this.imagemUrl});

  final String imagemUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return InkWell(
      onTap: () => AppSnackbar.showInfo(context, 'Viewer em breve'),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Image.network(
          CloudinaryUrl.otimizar(imagemUrl, largura: 800, altura: 1000),
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(color: colors.surfaceVariant);
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: colors.surfaceVariant,
            alignment: Alignment.center,
            child: Icon(
              Icons.broken_image,
              color: colors.textSecondary,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderAutor extends StatelessWidget {
  const _HeaderAutor({required this.publicacao});

  final Publicacao publicacao;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final p = publicacao;
    final foto = CloudinaryUrl.avatar(p.autorFoto, tamanho: 80);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                Navigator.pushNamed(context, '/perfil', arguments: p.autorId),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: colors.surfaceVariant,
              backgroundImage: foto != null ? NetworkImage(foto) : null,
              child: foto == null
                  ? Icon(Icons.person, color: colors.textSecondary)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/perfil',
                    arguments: p.autorId,
                  ),
                  child: Text(
                    p.autorNome,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colors.primary,
                    ),
                  ),
                ),
                if (p.autorUsername != null)
                  Text(
                    '@${p.autorUsername}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                Text(
                  _formatarDataHora(p.criadoEm),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatarDataHora(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(dt.day)}/${pad(dt.month)}/${dt.year}, ${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
  }
}

class _TagsWrap extends StatelessWidget {
  const _TagsWrap({required this.tags, required this.colors});

  final List<String> tags;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final tag in tags)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: AppRadius.pillRadius,
              ),
              child: Text(
                '#$tag',
                style: TextStyle(color: colors.primary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
