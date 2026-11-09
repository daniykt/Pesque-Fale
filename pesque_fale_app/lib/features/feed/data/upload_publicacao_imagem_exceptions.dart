class UploadArquivoMuitoGrandeException implements Exception {
  const UploadArquivoMuitoGrandeException();
}

class UploadFormatoInvalidoException implements Exception {
  const UploadFormatoInvalidoException();
}

class UploadPublicacaoImagemException implements Exception {
  const UploadPublicacaoImagemException(this.mensagem);
  final String mensagem;
}
