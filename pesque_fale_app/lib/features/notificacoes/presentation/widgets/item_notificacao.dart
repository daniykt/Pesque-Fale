import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatador_tempo_relativo.dart';
import '../../domain/notificacao.dart';
import '../utils/texto_notificacao.dart';
import 'avatar_com_tipo.dart';
import 'botao_seguir_de_volta.dart';

class ItemNotificacao extends StatelessWidget {
  const ItemNotificacao({
    super.key,
    required this.notif,
    required this.destacar,
    required this.onTap,
    required this.onSeguirDeVolta,
  });

  final Notificacao notif;
  final bool destacar;
  final VoidCallback onTap;
  final Future<bool> Function() onSeguirDeVolta;

  static const _formatador = FormatadorTempoRelativo();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final baseStyle = TextStyle(fontSize: 14, color: colors.textPrimary);
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: destacar ? colors.primary.withValues(alpha: 0.05) : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarComTipo(nome: notif.de, foto: notif.deFoto, tipo: notif.tipo),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: spansDaNotificacao(notif, baseStyle, boldStyle),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (!notif.lida) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                      ],
                      Text(
                        _formatador.formatar(notif.criadoEm),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (notif.tipo == TipoNotificacao.seguindo) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: BotaoSeguirDeVolta(
                        jaSigo: notif.jaSigoDe ?? false,
                        onSeguir: onSeguirDeVolta,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
