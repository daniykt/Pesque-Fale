import 'dart:async';
import 'dart:typed_data';

import 'upload_publicacao_imagem_repository.dart';

class UploadPublicacaoImagemRepositoryMock
    implements UploadPublicacaoImagemRepository {
  @override
  Future<String> upload(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final id = Object.hash(bytes.length, filename).abs();
    return 'https://res.cloudinary.com/mock/publicacoes/img_$id.jpg';
  }
}
