import 'dart:io';

abstract class UploadPublicacaoImagemRepository {
  /// Faz upload de uma imagem e retorna a URL do Cloudinary.
  /// Lança [UploadArquivoMuitoGrandeException] se > 5MB.
  /// Lança [UploadFormatoInvalidoException] se não for JPG/PNG/WEBP.
  Future<String> upload(File arquivo);
}
