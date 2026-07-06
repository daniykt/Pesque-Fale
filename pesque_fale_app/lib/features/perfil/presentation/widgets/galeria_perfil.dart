import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/publicacao.dart';

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
    if (publicacoes.isEmpty) {
      return _EstadoVazio(isOwnProfile: isOwnProfile);
    }

    return GridView.builder(
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
    return GestureDetector(
      onLongPressStart: (_) => setState(() => _pressionado = true),
      onLongPressEnd: (_) => setState(() => _pressionado = false),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(widget.publicacao.imagemUrl, fit: BoxFit.cover),
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
              onPressed: () => Navigator.pushNamed(context, '/publicar'),
              child: const Text('Nova Publicação'),
            ),
          ],
        ],
      ),
    );
  }
}
