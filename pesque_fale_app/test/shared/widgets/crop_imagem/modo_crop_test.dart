import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/shared/widgets/crop_imagem/modo_crop.dart';

void main() {
  group('ModoCrop.avatar', () {
    test('e circular, 1:1 e sai em 512x512', () {
      expect(ModoCrop.avatar.circular, isTrue);
      expect(ModoCrop.avatar.aspectRatio, 1.0);
      expect(ModoCrop.avatar.larguraSaida, 512);
      expect(ModoCrop.avatar.alturaSaida, 512);
    });
  });

  group('ModoCrop.banner', () {
    test('e retangular, 16:9 e sai em 1600x900', () {
      expect(ModoCrop.banner.circular, isFalse);
      expect(ModoCrop.banner.aspectRatio, 16 / 9);
      expect(ModoCrop.banner.larguraSaida, 1600);
      expect(ModoCrop.banner.alturaSaida, 900);
    });

    test('dimensoes de saida batem com o aspect ratio', () {
      expect(
        ModoCrop.banner.larguraSaida / ModoCrop.banner.alturaSaida,
        closeTo(ModoCrop.banner.aspectRatio, 0.0001),
      );
    });
  });
}
