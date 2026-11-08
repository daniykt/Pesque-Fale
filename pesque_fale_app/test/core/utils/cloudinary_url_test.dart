import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/core/utils/cloudinary_url.dart';

/// Documenta o CloudinaryUrl.otimizar como ele é hoje e o limitarLargura.
void main() {
  group('CloudinaryUrl.otimizar', () {
    test('URL do Cloudinary ganha a transformação logo após /upload/', () {
      expect(
        CloudinaryUrl.otimizar(
          'https://res.cloudinary.com/pesque-fale/image/upload/v1730000000/publicacoes/abc.jpg',
          largura: 360,
          altura: 360,
        ),
        'https://res.cloudinary.com/pesque-fale/image/upload/'
        'c_fill,w_360,h_360,q_auto,f_auto/v1730000000/publicacoes/abc.jpg',
      );
    });

    test('URL vazia passa igual', () {
      expect(CloudinaryUrl.otimizar('', largura: 360, altura: 360), '');
    });

    test('URL sem /upload/ passa igual', () {
      const picsum = 'https://picsum.photos/seed/ana-post-1/400/400';
      expect(CloudinaryUrl.otimizar(picsum, largura: 360, altura: 360), picsum);
    });
  });

  group('CloudinaryUrl.limitarLargura', () {
    test('URL do Cloudinary ganha c_limit só com a largura, sem corte', () {
      expect(
        CloudinaryUrl.limitarLargura(
          'https://res.cloudinary.com/pesque-fale/image/upload/v1730000000/publicacoes/abc.jpg',
          largura: 1080,
        ),
        'https://res.cloudinary.com/pesque-fale/image/upload/'
        'c_limit,w_1080,q_auto,f_auto/v1730000000/publicacoes/abc.jpg',
      );
    });

    test('URL vazia passa igual', () {
      expect(CloudinaryUrl.limitarLargura('', largura: 1080), '');
    });

    test('URL sem /upload/ passa igual', () {
      const picsum = 'https://picsum.photos/seed/ana-post-1/400/400';
      expect(CloudinaryUrl.limitarLargura(picsum, largura: 1080), picsum);
    });
  });
}
