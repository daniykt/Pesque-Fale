import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/cloudinary_url.dart';
import '../../domain/conversa.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({
    super.key,
    required this.conversa,
    required this.outroDigitando,
  });

  final Conversa conversa;
  final bool outroDigitando;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _abrirPerfil(BuildContext context) {
    Navigator.pushNamed(context, '/perfil', arguments: conversa.outroId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final foto = CloudinaryUrl.avatar(conversa.outroFoto, tamanho: 80);

    return AppBar(
      titleSpacing: 0,
      title: InkWell(
        onTap: () => _abrirPerfil(context),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.surfaceVariant,
              backgroundImage: foto != null ? NetworkImage(foto) : null,
              child: foto == null
                  ? Icon(Icons.person, color: colors.textSecondary)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversa.outroNome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (outroDigitando)
                    Text(
                      'está digitando...',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (valor) {
            if (valor == 'perfil') _abrirPerfil(context);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'perfil', child: Text('Ver perfil')),
          ],
        ),
      ],
    );
  }
}
