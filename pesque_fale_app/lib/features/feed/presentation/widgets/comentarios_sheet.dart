import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/comentarios_repository.dart';
import '../../domain/publicacao.dart';
import '../../providers/comentarios_provider.dart';
import '../../providers/feed_provider.dart';
import 'comentario_item.dart';

class ComentariosSheet {
  ComentariosSheet._();

  static void show(BuildContext context, Publicacao publicacao) {
    final feedProvider = context.read<FeedProvider>();
    final comentariosRepo = context.read<ComentariosRepository>();
    final authProvider = context.read<AuthProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => ChangeNotifierProvider<ComentariosProvider>(
        create: (_) => ComentariosProvider(
          repository: comentariosRepo,
          publicacaoId: publicacao.id,
          authProvider: authProvider,
          onCountChange: (delta) =>
              feedProvider.atualizarContadorComentarios(publicacao.id, delta),
        )..carregarInicial(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) =>
              _ConteudoSheet(scrollController: scrollController),
        ),
      ),
    );
  }
}

class _ConteudoSheet extends StatefulWidget {
  const _ConteudoSheet({required this.scrollController});

  final ScrollController scrollController;

  @override
  State<_ConteudoSheet> createState() => _ConteudoSheetState();
}

class _ConteudoSheetState extends State<_ConteudoSheet> {
  final _controller = TextEditingController();
  bool _temTexto = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    _controller.addListener(() {
      final temTexto = _controller.text.trim().isNotEmpty;
      if (temTexto != _temTexto) setState(() => _temTexto = temTexto);
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    final position = widget.scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<ComentariosProvider>().carregarMais();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<ComentariosProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 12),
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Comentários',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Divider(height: 24, color: colors.border),
          Expanded(child: _buildLista(provider, authProvider, colors)),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Adicione um comentário...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: colors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _temTexto ? colors.primary : colors.textSecondary,
                  ),
                  onPressed: _temTexto ? _enviar : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(
    ComentariosProvider provider,
    AuthProvider authProvider,
    AppColors colors,
  ) {
    if (provider.status == StatusComentarios.carregando) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, _) => _ComentarioSkeletonRow(colors: colors),
      );
    }

    if (provider.status == StatusComentarios.vazio) {
      return Center(
        child: Text(
          'Nenhum comentário ainda. Seja o primeiro!',
          style: TextStyle(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    final comentarios = provider.comentarios;
    return ListView.separated(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: comentarios.length + (provider.carregandoMais ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, index) {
        if (index >= comentarios.length) {
          return _ComentarioSkeletonRow(colors: colors);
        }
        final comentario = comentarios[index];
        return ComentarioItem(
          comentario: comentario,
          souAutor: comentario.autorId == authProvider.usuario?.id,
          onDelete: () => _confirmarDelete(comentario.id),
        );
      },
    );
  }

  Future<void> _confirmarDelete(String comentarioId) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir comentário'),
        content: const Text('Tem certeza que deseja excluir este comentário?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    try {
      await context.read<ComentariosProvider>().deletar(comentarioId);
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(context, 'Não foi possível excluir o comentário');
      }
    }
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.usuario == null) {
      AppSnackbar.showInfo(context, 'Faça login para comentar');
      return;
    }

    _controller.clear();
    try {
      await context.read<ComentariosProvider>().enviar(texto);
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(context, 'Não foi possível enviar');
        _controller.text = texto;
      }
    }
  }
}

class _ComentarioSkeletonRow extends StatelessWidget {
  const _ComentarioSkeletonRow({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    Widget box({double width = double.infinity, double height = 12}) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: width,
          height: height,
          color: colors.surfaceVariant,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(width: 32, height: 32, color: colors.surfaceVariant),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              box(width: 120, height: 12),
              const SizedBox(height: 6),
              box(height: 12),
              const SizedBox(height: 6),
              box(width: 60, height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
