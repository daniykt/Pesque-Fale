import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class ImagemCarregando extends StatefulWidget {
  const ImagemCarregando({super.key, this.tamanhoIcone = 48});

  final double tamanhoIcone;

  @override
  State<ImagemCarregando> createState() => _ImagemCarregandoState();
}

class _ImagemCarregandoState extends State<ImagemCarregando>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);
  late final Animation<double> _opacidade = Tween<double>(
    begin: 0.4,
    end: 0.75,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Semantics(
      label: 'Carregando imagem',
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: _opacidade,
            child: ColoredBox(color: colors.border),
          ),
          Center(
            child: Icon(
              Icons.image_outlined,
              color: colors.textSecondary,
              size: widget.tamanhoIcone,
            ),
          ),
        ],
      ),
    );
  }
}

class ImagemIndisponivel extends StatelessWidget {
  const ImagemIndisponivel({
    super.key,
    this.icone = Icons.broken_image_outlined,
    this.tamanhoIcone = 48,
    this.mostrarTexto = true,
  });

  final IconData icone;
  final double tamanhoIcone;
  final bool mostrarTexto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Semantics(
      label: 'Imagem indisponível',
      child: Container(
        color: colors.border,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, color: colors.textSecondary, size: tamanhoIcone),
            if (mostrarTexto) ...[
              const SizedBox(height: AppSpacing.xs),
              ExcludeSemantics(
                child: Text(
                  'Imagem indisponível',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
