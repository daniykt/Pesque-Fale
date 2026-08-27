abstract class NotificacoesException implements Exception {
  const NotificacoesException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NaoAutenticadoException extends NotificacoesException {
  const NaoAutenticadoException()
    : super('Faça login para ver suas notificações.');
}

class NetworkException extends NotificacoesException {
  const NetworkException() : super('Sem conexão com o servidor.');
}

class InternalServerException extends NotificacoesException {
  const InternalServerException()
    : super('Erro no servidor. Tente novamente.');
}
