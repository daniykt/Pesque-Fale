abstract class PontosException implements Exception {
  const PontosException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NetworkException extends PontosException {
  const NetworkException() : super('Sem conexão com o servidor.');
}

class InternalServerException extends PontosException {
  const InternalServerException() : super('Erro no servidor. Tente novamente.');
}
