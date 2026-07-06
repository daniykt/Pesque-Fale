abstract class PerfilException implements Exception {
  const PerfilException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PerfilNaoEncontradoException extends PerfilException {
  const PerfilNaoEncontradoException() : super('Usuário não encontrado.');
}

class FotoMuitoGrandeException extends PerfilException {
  const FotoMuitoGrandeException() : super('A imagem deve ter no máximo 5MB.');
}

class FormatoInvalidoException extends PerfilException {
  const FormatoInvalidoException() : super('Formato de imagem inválido.');
}

class UsernameJaCadastradoException extends PerfilException {
  const UsernameJaCadastradoException()
    : super('Este username já está em uso.');
}

/// Erro de validação genérico do backend (ex.: nome curto demais), com o
/// mapa de campo -> mensagem para hidratar o formulário.
class PerfilValidationException extends PerfilException {
  PerfilValidationException(this.fieldErrors)
    : super('Verifique os campos e tente novamente.');

  final Map<String, String> fieldErrors;
}

/// Lançada quando o endpoint chamado ainda não existe no backend
/// (gap de contrato — ver issue de continuação da Fase 2).
class RecursoNaoDisponivelException extends PerfilException {
  const RecursoNaoDisponivelException()
    : super('Esse recurso ainda não está disponível.');
}

class NetworkException extends PerfilException {
  const NetworkException() : super('Sem conexão com o servidor.');
}

class InternalServerException extends PerfilException {
  const InternalServerException() : super('Erro no servidor. Tente novamente.');
}
