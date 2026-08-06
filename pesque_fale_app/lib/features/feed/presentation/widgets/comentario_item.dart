import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/cloudinary_url.dart';
import '../../../../core/utils/tempo_relativo.dart';
import '../../domain/comentario.dart';

class ComentarioItem extends StatelessWidget {
  const ComentarioItem({
    super.key,
    required this.comentario,
    required this.souAutor,
    required this.onDelete,
  });

  final Comentario comentario;
  final bool souAutor;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final foto = CloudinaryUrl.avatar(comentario.autorFoto, tamanho: 64);

    final conteudo = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: colors.surfaceVariant,
          backgroundImage: foto != null ? NetworkImage(foto) : null,
          child: foto == null
              ? Icon(Icons.person, size: 16, color: colors.textSecondary)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      comentario.autorNome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (comentario.autorUsername != null) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '@${comentario.autorUsername}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(comentario.texto, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                TempoRelativo.formatar(comentario.criadoEm),
                style: TextStyle(color: colors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        if (souAutor)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
          ),
      ],
    );

    return comentario.enviando
        ? Opacity(opacity: 0.5, child: conteudo)
        : conteudo;
  }
}
