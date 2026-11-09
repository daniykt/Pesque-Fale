import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/cloudinary_url.dart';
import 'secao_titulo.dart';

class SecaoGaleria extends StatelessWidget {
  const SecaoGaleria({super.key, required this.fotos});

  final List<String> fotos;

  @override
  Widget build(BuildContext context) {
    if (fotos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SecaoTitulo('FOTOS'),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: fotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _GaleriaViewer.abrir(context, fotos, index),
                  child: ClipRRect(
                    borderRadius: AppRadius.mdRadius,
                    child: Image.network(
                      CloudinaryUrl.otimizar(
                        fotos[index],
                        largura: 280,
                        altura: 280,
                      ),
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 140,
                        height: 140,
                        color: Colors.black12,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GaleriaViewer extends StatefulWidget {
  const _GaleriaViewer({required this.fotos, required this.indiceInicial});

  final List<String> fotos;
  final int indiceInicial;

  static void abrir(BuildContext context, List<String> fotos, int indice) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _GaleriaViewer(fotos: fotos, indiceInicial: indice),
      ),
    );
  }

  @override
  State<_GaleriaViewer> createState() => _GaleriaViewerState();
}

class _GaleriaViewerState extends State<_GaleriaViewer> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.indiceInicial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.fotos.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.fotos[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.xs,
            right: AppSpacing.md,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
