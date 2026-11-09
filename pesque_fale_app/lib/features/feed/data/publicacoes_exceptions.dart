abstract class PublicacoesException implements Exception {
  const PublicacoesException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PublicacaoNaoEncontradaException extends PublicacoesException {
  const PublicacaoNaoEncontradaException()
    : super('Publicação não encontrada.');
}

class NaoAutenticadoException extends PublicacoesException {
  const NaoAutenticadoException()
    : super('Faça login para ver publicações de quem você segue.');
}

class ForbiddenException extends PublicacoesException {
  const ForbiddenException() : super('Você não tem permissão para essa ação.');
}

class TextoInvalidoException extends PublicacoesException {
  const TextoInvalidoException()
    : super('O comentário deve ter entre 1 e 500 caracteres.');
}

class ComentarioNaoEncontradoException extends PublicacoesException {
  const ComentarioNaoEncontradoException()
    : super('Comentário não encontrado.');
}

class NetworkException extends PublicacoesException {
  const NetworkException() : super('Sem conexão com o servidor.');
}

class InternalServerException extends PublicacoesException {
  const InternalServerException() : super('Erro no servidor. Tente novamente.');
}
