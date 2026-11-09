abstract class AssistenteException implements Exception {
  const AssistenteException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NaoAutenticadoException extends AssistenteException {
  const NaoAutenticadoException()
    : super('Faça login de novo para conversar com o assistente.');
}

class NetworkException extends AssistenteException {
  const NetworkException()
    : super('Sem conexão com o servidor. Confira sua internet e tente de novo.');
}

class LimiteAssistenteException extends AssistenteException {
  const LimiteAssistenteException()
    : super('Você fez muitas perguntas seguidas. Descanse um pouquinho e tente de novo mais tarde.');
}

class AssistenteIndisponivelException extends AssistenteException {
  const AssistenteIndisponivelException()
    : super('O assistente está descansando um pouquinho. Tente de novo em alguns minutos.');
}

class PerguntaInvalidaException extends AssistenteException {
  const PerguntaInvalidaException()
    : super('Não entendi a pergunta. Tente escrever de outro jeito, com até 500 letras.');
}

class InternalServerException extends AssistenteException {
  const InternalServerException()
    : super('Algo deu errado. Tente de novo.');
}