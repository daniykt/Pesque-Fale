import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/cloudinary_url.dart';
import '../../../auth/providers/auth_provider.dart';

class PublicarHeaderBar extends StatelessWidget {
  const PublicarHeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final usuario = context.watch<AuthProvider>().usuario;
    final foto = CloudinaryUrl.avatar(usuario?.fotoPerfil, tamanho: 80);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.surfaceVariant,
            backgroundImage: foto != null ? NetworkImage(foto) : null,
            child: foto == null
                ? Icon(Icons.person, color: colors.textSecondary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.of(context).pushNamed('/publicacao/nova'),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(24),
                  color: colors.surface,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'O que você deseja publicar hoje',
                        style: TextStyle(color: colors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 22,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
