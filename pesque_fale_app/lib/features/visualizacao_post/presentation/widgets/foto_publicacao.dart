import 'package:flutter/material.dart';

import '../../../../core/utils/cloudinary_url.dart';
import '../../../../shared/widgets/imagem_placeholder.dart';

/// Foto do detalhe num quadro fixo 1:1: largura total, altura igual à
/// largura e `BoxFit.cover`. Todo post fica com a mesma altura.
class FotoPublicacao extends StatelessWidget {
  const FotoPublicacao({
    super.key,
    required this.url,
    @visibleForTesting this.imagem,
  });

  final String url;

  /// Só para testes: a imagem de rede não carrega em widget test.
  final ImageProvider? imagem;

  // ~360dp × densidade 3, já cortada em quadrado no Cloudinary.
  ImageProvider get _imagem =>
      imagem ??
      NetworkImage(CloudinaryUrl.otimizar(url, largura: 1080, altura: 1080));

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      image: true,
      label: 'Foto da publicação',
      child: AspectRatio(
        aspectRatio: 1,
        child: Image(
          image: _imagem,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          frameBuilder: (context, child, frame, sincrono) {
            if (frame == null && !sincrono) return const ImagemCarregando();
            return child;
          },
          errorBuilder: (context, error, stackTrace) =>
              const ImagemIndisponivel(),
        ),
      ),
    );
  }
}
