import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/cloudinary_url.dart';
import '../../../../shared/widgets/imagem_placeholder.dart';
import '../../../../shared/widgets/visualizador_imagem.dart';

/// Foto do detalhe: largura total e altura de no máximo 4:5. Foto deitada
/// aparece inteira; foto em pé é cortada (`BoxFit.cover`). Tocar abre a
/// foto inteira em tela cheia.
class FotoPublicacao extends StatelessWidget {
  const FotoPublicacao({
    super.key,
    required this.url,
    @visibleForTesting this.imagem,
  });

  final String url;

  /// Só para testes: a imagem de rede não carrega em widget test.
  final ImageProvider? imagem;

  /// Largura ÷ altura no limite: a foto não fica mais alta que 4:5.
  static const proporcaoMinima = 4 / 5;

  // ~360dp × densidade 3. Sem corte, para a foto deitada sair inteira.
  ImageProvider get _imagem =>
      imagem ?? NetworkImage(CloudinaryUrl.limitarLargura(url, largura: 1080));

  @override
  Widget build(BuildContext context) {
    final provider = _imagem;

    return LayoutBuilder(
      builder: (context, constraints) {
        final alturaMaxima = constraints.maxWidth / proporcaoMinima;
        return Semantics(
          container: true,
          button: true,
          label: 'Foto da publicação. Toque para ampliar',
          child: InkWell(
            onTap: () => VisualizadorImagem.abrir(
              context,
              provider,
              descricao: 'Foto da publicação',
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: alturaMaxima),
              child: Image(
                image: provider,
                width: double.infinity,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, sincrono) {
                  if (frame == null && !sincrono) {
                    return const AspectRatio(
                      aspectRatio: proporcaoMinima,
                      child: ImagemCarregando(),
                    );
                  }
                  return Stack(
                    children: [
                      child,
                      const Positioned(
                        right: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                        child: _SeloAmpliar(),
                      ),
                    ],
                  );
                },
                errorBuilder: (context, error, stackTrace) => const AspectRatio(
                  aspectRatio: proporcaoMinima,
                  child: ImagemIndisponivel(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeloAmpliar extends StatelessWidget {
  const _SeloAmpliar();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.85),
          borderRadius: AppRadius.pillRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.zoom_out_map, size: 14, color: colors.textPrimary),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                'Toque para ampliar',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
