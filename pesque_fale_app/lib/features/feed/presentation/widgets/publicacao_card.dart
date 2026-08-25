import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/cloudinary_url.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/publicacao.dart';
import 'acoes_bar.dart';
import 'comentarios_sheet.dart';
import 'publicacao_menu_sheet.dart';

class PublicacaoCard extends StatelessWidget {
  const PublicacaoCard({super.key, required this.publicacao});

  final Publicacao publicacao;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final p = publicacao;
    final foto = CloudinaryUrl.avatar(p.autorFoto, tamanho: 80);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.mdRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/perfil',
                    arguments: p.autorId,
                  ),
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
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        _metaLine(p),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => PublicacaoMenuSheet.show(context, p),
                ),
              ],
            ),
          ),
          if (p.descricao != null && p.descricao!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: Text(p.descricao!, style: const TextStyle(fontSize: 14)),
            ),
          if (p.imagemUrl != null)
            InkWell(
              onTap: () => AppSnackbar.showInfo(context, 'Detalhes em breve'),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Image.network(
                  CloudinaryUrl.otimizar(
                    p.imagemUrl!,
                    largura: 800,
                    altura: 1000,
                  ),
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
            ),
          if (p.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in p.tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
            ),
          AcoesBar(
            publicacao: p,
            onComentarTap: () => ComentariosSheet.show(context, p),
          ),
        ],
      ),
    );
  }

  String _metaLine(Publicacao p) {
    final local = p.localTexto ?? '';
    final data = _formatarDataHora(p.criadoEm);
    return local.isNotEmpty ? '$local · $data' : data;
  }

  String _formatarDataHora(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(dt.day)}/${pad(dt.month)}/${dt.year}, ${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
  }
}
