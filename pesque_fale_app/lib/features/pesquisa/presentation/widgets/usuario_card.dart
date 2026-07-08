import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/usuario_resumo.dart';

class UsuarioCard extends StatelessWidget {
  const UsuarioCard({
    super.key,
    required this.usuario,
    required this.onVerPerfil,
  });

  final UsuarioResumo usuario;
  final VoidCallback onVerPerfil;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final temFoto =
        usuario.fotoPerfil != null && usuario.fotoPerfil!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colors.primary,
                backgroundImage: temFoto
                    ? NetworkImage(usuario.fotoPerfil!)
                    : null,
                child: temFoto
                    ? null
                    : Text(
                        usuario.nome.isNotEmpty
                            ? usuario.nome[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nome,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '@${usuario.username}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (usuario.bio.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        usuario.bio,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: onVerPerfil,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
              child: const Text('Ver perfil'),
            ),
          ),
        ],
      ),
    );
  }
}
