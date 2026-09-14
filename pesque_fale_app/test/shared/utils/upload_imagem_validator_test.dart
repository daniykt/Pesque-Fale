import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pesque_fale_app/shared/utils/upload_imagem_validator.dart';

/// Monta um XFile em memória, sem tocar o disco.
///
/// `path` é passado junto com `name` de propósito: na implementação IO do
/// cross_file (a que roda em `flutter test`) o parâmetro `name` é ignorado e
/// o getter `.name` deriva do path. No web vale o `name`. Passando os dois,
/// o fake fica correto nas duas plataformas.
///
/// `length` é honrado pelo XFile, então dá pra simular um arquivo grande sem
/// alocar os bytes correspondentes.
XFile _fakeXFile({required String name, int tamanhoBytes = 100}) {
  return XFile.fromData(
    Uint8List.fromList(List<int>.filled(1, 0)),
    name: name,
    path: name,
    length: tamanhoBytes,
  );
}

void main() {
  group('extrairExtensao', () {
    test('retorna a extensao em minusculo', () {
      expect(
        UploadImagemValidator.extrairExtensao(_fakeXFile(name: 'foto.JPG')),
        'jpg',
      );
      expect(
        UploadImagemValidator.extrairExtensao(_fakeXFile(name: 'foto.WebP')),
        'webp',
      );
    });

    test('considera apenas o trecho apos o ultimo ponto', () {
      expect(
        UploadImagemValidator.extrairExtensao(
          _fakeXFile(name: 'minha.foto.de.pesca.png'),
        ),
        'png',
      );
    });

    test('nome sem extensao retorna o nome inteiro (edge case)', () {
      expect(
        UploadImagemValidator.extrairExtensao(_fakeXFile(name: 'foto')),
        'foto',
      );
    });
  });

  group('formatoValido', () {
    test('aceita os quatro formatos suportados', () {
      for (final extensao in ['jpg', 'jpeg', 'png', 'webp']) {
        expect(
          UploadImagemValidator.formatoValido(_fakeXFile(name: 'f.$extensao')),
          isTrue,
          reason: '$extensao deveria ser aceito',
        );
      }
    });

    test('recusa formatos nao suportados', () {
      for (final extensao in ['gif', 'heic', 'bmp']) {
        expect(
          UploadImagemValidator.formatoValido(_fakeXFile(name: 'f.$extensao')),
          isFalse,
          reason: '$extensao nao deveria ser aceito',
        );
      }
    });

    test('recusa arquivo sem extensao', () {
      expect(
        UploadImagemValidator.formatoValido(_fakeXFile(name: 'foto')),
        isFalse,
      );
    });
  });

  group('tamanhoValido', () {
    test('aceita arquivo menor que o limite', () async {
      final arquivo = _fakeXFile(name: 'f.jpg', tamanhoBytes: 1024);
      expect(await UploadImagemValidator.tamanhoValido(arquivo), isTrue);
    });

    test('aceita arquivo exatamente no limite', () async {
      final arquivo = _fakeXFile(
        name: 'f.jpg',
        tamanhoBytes: UploadImagemValidator.tamanhoMaximoBytes,
      );
      expect(await UploadImagemValidator.tamanhoValido(arquivo), isTrue);
    });

    test('recusa arquivo acima do limite', () async {
      final arquivo = _fakeXFile(
        name: 'f.jpg',
        tamanhoBytes: UploadImagemValidator.tamanhoMaximoBytes + 1,
      );
      expect(await UploadImagemValidator.tamanhoValido(arquivo), isFalse);
    });
  });
}
