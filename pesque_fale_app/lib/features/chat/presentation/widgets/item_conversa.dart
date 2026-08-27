import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/cloudinary_url.dart';
import '../../../../core/utils/formatador_data_conversa.dart';
import '../../domain/conversa.dart';
import 'badge_nao_lidas.dart';

class ItemConversa extends StatelessWidget {
  const ItemConversa({super.key, required this.conversa, required this.onTap});

  final Conversa conversa;
  final VoidCallback onTap;

  static const _formatador = FormatadorDataConversa();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final foto = CloudinaryUrl.avatar(conversa.outroFoto, tamanho: 96);
    final temNaoLidas = conversa.naoLidas > 0;
    final corDestaque = temNaoLidas ? colors.primary : colors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversa.outroNome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        conversa.ultimaMensagemEm != null
                            ? _formatador.formatar(conversa.ultimaMensagemEm!)
                            : '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: temNaoLidas
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: corDestaque,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversa.ultimaMensagem ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: temNaoLidas
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: corDestaque,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (temNaoLidas) ...[
                        const SizedBox(width: AppSpacing.xs),
                        BadgeNaoLidas(quantidade: conversa.naoLidas),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
