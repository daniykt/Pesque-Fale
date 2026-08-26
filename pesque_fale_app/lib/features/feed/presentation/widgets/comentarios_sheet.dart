import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/comentarios_repository.dart';
import '../../domain/publicacao.dart';
import '../../providers/comentarios_provider.dart';
import '../../providers/feed_provider.dart';
import 'comentario_input_bar.dart';
import 'comentarios_lista.dart';

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

class _ConteudoSheet extends StatelessWidget {
  const _ConteudoSheet({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
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
        Expanded(child: ComentariosLista(scrollController: scrollController)),
        const ComentarioInputBar(),
      ],
    );
  }
}
