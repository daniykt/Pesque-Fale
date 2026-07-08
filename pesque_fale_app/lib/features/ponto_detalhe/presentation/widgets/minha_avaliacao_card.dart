import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/cloudinary_url.dart';
import '../../domain/avaliacao.dart';
import 'avaliacao_card.dart';

class MinhaAvaliacaoCard extends StatelessWidget {
  const MinhaAvaliacaoCard({
    super.key,
    required this.avaliacao,
    required this.onEditar,
    required this.onExcluir,
  });

  final Avaliacao avaliacao;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final fotoUrl = CloudinaryUrl.avatar(avaliacao.usuarioFoto, tamanho: 80);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        border: Border.all(color: colors.primary, width: 1.5),
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SUA AVALIAÇÃO',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colors.textSecondary),
                onSelected: (valor) {
                  if (valor == 'editar') onEditar();
                  if (valor == 'excluir') onExcluir();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                ],
              ),
            ],
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.surfaceVariant,
                backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
                child: fotoUrl == null
                    ? Text(
                        avaliacao.usuarioNome.isNotEmpty
                            ? avaliacao.usuarioNome[0].toUpperCase()
                            : '?',
                        style: TextStyle(color: colors.textPrimary),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  avaliacao.usuarioNome,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              ...estrelasFrom(avaliacao.nota),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                avaliacao.nota.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (avaliacao.comentario != null &&
              avaliacao.comentario!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              avaliacao.comentario!,
              style: TextStyle(color: colors.textPrimary),
            ),
          ],
          if (avaliacao.foiEditada) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '(editada)',
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
