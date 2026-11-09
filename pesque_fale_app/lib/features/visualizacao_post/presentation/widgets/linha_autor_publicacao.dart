import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/cloudinary_url.dart';
import '../../../../core/utils/tempo_relativo.dart';
import '../../../../shared/widgets/badge_equipe/badge_nome_usuario.dart';
import '../../../feed/domain/publicacao.dart';

/// Linha do autor da publicação: avatar, nome com selo e "@username · tempo"
/// num alvo só que abre o perfil, e o ⋯ no fim.
///
/// Com [mostrarLocal] (card do feed), o local entra numa linha própria logo
/// abaixo, fora do toque do perfil. O detalhe mostra o local no card de
/// local, então não liga essa opção.
class LinhaAutorPublicacao extends StatelessWidget {
  const LinhaAutorPublicacao({
    super.key,
    required this.publicacao,
    required this.onMenu,
    this.mostrarLocal = false,
  });

  final Publicacao publicacao;
  final VoidCallback onMenu;
  final bool mostrarLocal;

  static const _raioAvatar = 20.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textos = Theme.of(context).textTheme;
    final p = publicacao;
    final foto = CloudinaryUrl.avatar(p.autorFoto, tamanho: 80);
    final tempo = TempoRelativo.formatar(p.criadoEm);
    final meta = p.autorUsername != null
        ? '@${p.autorUsername} · $tempo'
        : tempo;
    final local = p.localTexto?.trim();
    final temLocal = mostrarLocal && local != null && local.isNotEmpty;

    final linhaAutor = Row(
      children: [
        // Avatar, nome e meta num alvo só, que abre o perfil.
        Expanded(
          child: InkWell(
            key: const ValueKey('detalhe-autor'),
            borderRadius: AppRadius.mdRadius,
            onTap: () =>
                Navigator.pushNamed(context, '/perfil', arguments: p.autorId),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimension,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: _raioAvatar,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BadgeNomeUsuario(
                            userId: p.autorId,
                            nome: Text(
                              p.autorNome,
                              style: textos.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: colors.primaryAccent,
                              ),
                            ),
                          ),
                          Text(
                            meta,
                            style: textos.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: colors.textSecondary),
          tooltip: 'Mais opções',
          onPressed: onMenu,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xxs,
        AppSpacing.xs,
      ),
      child: temLocal
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                linhaAutor,
                // Alinhado ao nome: padding do alvo + avatar + espaço.
                Padding(
                  key: const ValueKey('linha-autor-local'),
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xxs + _raioAvatar * 2 + AppSpacing.sm,
                    right: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: colors.primaryAccent,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          local,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textos.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.primaryAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : linhaAutor,
    );
  }
}
