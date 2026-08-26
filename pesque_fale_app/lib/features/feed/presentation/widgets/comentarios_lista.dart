import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/comentarios_provider.dart';
import 'comentario_item.dart';

class ComentariosLista extends StatefulWidget {
  const ComentariosLista({
    super.key,
    this.scrollController,
    this.shrinkWrap = false,
    this.physics,
  });

  final ScrollController? scrollController;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  State<ComentariosLista> createState() => _ComentariosListaState();
}

class _ComentariosListaState extends State<ComentariosLista> {
  late final ScrollController _controller;
  late final bool _controllerProprio;

  @override
  void initState() {
    super.initState();
    _controllerProprio = widget.scrollController == null;
    _controller = widget.scrollController ?? ScrollController();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    if (_controllerProprio) _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<ComentariosProvider>().carregarMais();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<ComentariosProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (provider.status == StatusComentarios.carregando) {
      return ListView.separated(
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
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
      controller: _controller,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
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
