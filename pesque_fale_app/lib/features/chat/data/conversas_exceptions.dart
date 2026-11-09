abstract class ConversasException implements Exception {
  const ConversasException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NaoAutenticadoException extends ConversasException {
  const NaoAutenticadoException()
    : super('Faça login para ver suas conversas.');
}

class NetworkException extends ConversasException {
  const NetworkException() : super('Sem conexão com o servidor.');
}

class InternalServerException extends ConversasException {
  const InternalServerException()
    : super('Erro no servidor. Tente novamente.');
}
