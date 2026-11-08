import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/core/utils/cloudinary_url.dart';

/// Documenta o CloudinaryUrl.otimizar como ele é hoje.
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
}
