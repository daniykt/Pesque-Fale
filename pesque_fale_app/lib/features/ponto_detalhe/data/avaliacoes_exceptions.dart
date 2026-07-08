abstract class AvaliacoesException implements Exception {
  const AvaliacoesException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AvaliacoesException {
  const NetworkException() : super('Sem conexão com o servidor.');
}

class InternalServerException extends AvaliacoesException {
  const InternalServerException()
    : super('Erro no servidor. Tente novamente.');
}

class NaoAutenticadoException extends AvaliacoesException {
  const NaoAutenticadoException()
    : super('Faça login para avaliar este ponto.');
}

class JaAvaliouException extends AvaliacoesException {
  const JaAvaliouException()
    : super('Você já avaliou este ponto. Edite sua avaliação existente.');
}

class AvaliacaoNaoEncontradaException extends AvaliacoesException {
  const AvaliacaoNaoEncontradaException()
    : super('Avaliação não encontrada.');
}

class AvaliacoesPontoNaoEncontradoException extends AvaliacoesException {
  const AvaliacoesPontoNaoEncontradoException()
    : super('Ponto de pesca não encontrado.');
}

class AvaliacoesValidationException extends AvaliacoesException {
  const AvaliacoesValidationException(super.message);
}
