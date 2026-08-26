import 'dart:async';
import 'dart:io';

import 'upload_publicacao_imagem_repository.dart';

class UploadPublicacaoImagemRepositoryMock
    implements UploadPublicacaoImagemRepository {
  @override
  Future<String> upload(File arquivo) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final id = arquivo.path.hashCode.abs();
    return 'https://res.cloudinary.com/mock/publicacoes/img_$id.jpg';
  }
}
