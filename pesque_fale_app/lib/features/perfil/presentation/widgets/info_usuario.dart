import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/domain/usuario.dart';

class InfoUsuario extends StatefulWidget {
  const InfoUsuario({super.key, required this.usuario});

  final Usuario usuario;

  @override
  State<InfoUsuario> createState() => _InfoUsuarioState();
}

class _InfoUsuarioState extends State<InfoUsuario> {
  bool _bioExpandida = false;

  void _copiarUsername(BuildContext context, String username) {
    Clipboard.setData(ClipboardData(text: '@$username'));
    AppSnackbar.showSuccess(context, 'Username copiado!');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final usuario = widget.usuario;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(usuario.nome, style: Theme.of(context).textTheme.titleLarge),
        if (usuario.username != null && usuario.username!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: GestureDetector(
              onTap: () => _copiarUsername(context, usuario.username!),
              child: Text(
                '@${usuario.username}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
            ),
          ),
        if (usuario.localizacao != null && usuario.localizacao!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  usuario.localizacao!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        if (usuario.bio != null && usuario.bio!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final style = Theme.of(context).textTheme.bodyMedium;
                final estoura = _textoEstoura(
                  usuario.bio!,
                  style,
                  constraints.maxWidth,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.bio!,
                      maxLines: _bioExpandida ? null : 5,
                      overflow: _bioExpandida ? null : TextOverflow.ellipsis,
                      style: style,
                    ),
                    if (estoura)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _bioExpandida = !_bioExpandida),
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxs),
                          child: Text(
                            _bioExpandida ? 'ver menos' : 'ver mais',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  bool _textoEstoura(String texto, TextStyle? style, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: texto, style: style),
      maxLines: 5,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }
}
