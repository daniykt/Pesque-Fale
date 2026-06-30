class FieldError {
  const FieldError({required this.campo, required this.mensagem});

  final String campo;
  final String mensagem;

  factory FieldError.fromJson(Map<String, dynamic> json) {
    return FieldError(
      campo: json['campo']?.toString() ?? 'geral',
      mensagem: json['mensagem']?.toString() ?? '',
    );
  }
}

abstract class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ValidationException extends AuthException {
  const ValidationException(this.errors)
    : super('Verifique os campos e tente novamente.');

  final List<FieldError> errors;
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
