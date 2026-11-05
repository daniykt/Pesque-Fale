import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../feed/domain/publicacao.dart';

class GaleriaPerfil extends StatelessWidget {
  const GaleriaPerfil({
    super.key,
    required this.publicacoes,
    required this.isOwnProfile,
  });

  final List<Publicacao> publicacoes;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Semantics(
            header: true,
            child: Text(
              'Publicações',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        if (publicacoes.isEmpty)
          _EstadoVazio(isOwnProfile: isOwnProfile)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: publicacoes.length,
            itemBuilder: (context, index) =>
                _ItemGaleria(publicacao: publicacoes[index]),
          ),
      ],
    );
  }
}

class _ItemGaleria extends StatefulWidget {
  const _ItemGaleria({required this.publicacao});

  final Publicacao publicacao;

  @override
  State<_ItemGaleria> createState() => _ItemGaleriaState();
}

class _ItemGaleriaState extends State<_ItemGaleria> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    final imagemUrl = widget.publicacao.imagemUrl;

    return GestureDetector(
      onLongPressStart: (_) => setState(() => _pressionado = true),
      onLongPressEnd: (_) => setState(() => _pressionado = false),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imagemUrl == null || imagemUrl.isEmpty)
            const _PlaceholderImagem()
          else
            Image.network(
              imagemUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _PlaceholderImagem(),
            ),
          if (_pressionado)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 16),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '${widget.publicacao.curtidasCount}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.mode_comment_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '${widget.publicacao.comentariosCount}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceholderImagem extends StatelessWidget {
  const _PlaceholderImagem();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      color: colors.surfaceVariant,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: colors.textSecondary,
        size: 32,
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({required this.isOwnProfile});

  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.photo_camera_back_outlined,
            size: 48,
            color: colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nenhuma publicação ainda',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          if (isOwnProfile) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/publicacao/nova'),
              child: const Text('Nova Publicação'),
            ),
          ],
        ],
      ),
    );
  }
}
