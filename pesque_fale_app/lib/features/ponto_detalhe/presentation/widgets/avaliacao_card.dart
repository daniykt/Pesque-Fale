import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/cloudinary_url.dart';
import '../../../../core/utils/tempo_relativo.dart';
import '../../domain/avaliacao.dart';

class AvaliacaoCard extends StatelessWidget {
  const AvaliacaoCard({super.key, required this.avaliacao});

  final Avaliacao avaliacao;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final fotoUrl = CloudinaryUrl.avatar(avaliacao.usuarioFoto, tamanho: 80);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avaliacao.usuarioNome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '@${avaliacao.usuarioUsername}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                TempoRelativo.formatar(avaliacao.criadoEm),
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
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
            Text(avaliacao.comentario!, style: TextStyle(color: colors.textPrimary)),
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

List<Widget> estrelasFrom(double nota) {
  final cheias = nota.floor();
  final temMeia = (nota - cheias) >= 0.5;

  return List.generate(5, (i) {
    IconData icon;
    if (i < cheias) {
      icon = Icons.star;
    } else if (i == cheias && temMeia) {
      icon = Icons.star_half;
    } else {
      icon = Icons.star_border;
    }
    return Icon(icon, size: 16, color: Colors.amber);
  });
}
