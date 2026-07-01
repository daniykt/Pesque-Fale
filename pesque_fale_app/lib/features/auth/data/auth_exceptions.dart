abstract class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ValidationException extends AuthException {
  ValidationException(this.fieldErrors)
    : super('Verifique os campos e tente novamente.');

  final Map<String, String> fieldErrors;
}

class EmailJaCadastradoException extends AuthException {
  const EmailJaCadastradoException() : super('Este email já está em uso.');
}

class CredenciaisInvalidasException extends AuthException {
  const CredenciaisInvalidasException() : super('Email ou senha incorretos.');
}

class NetworkException extends AuthException {
  const NetworkException() : super('Sem conexão com o servidor.');
}

class InternalServerException extends AuthException {
  const InternalServerException() : super('Erro no servidor. Tente novamente.');
}
