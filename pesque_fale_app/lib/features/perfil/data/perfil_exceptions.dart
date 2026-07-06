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
  const FotoMuitoGrandeException()
    : super('A imagem deve ter no máximo 5MB.');
}

class FormatoInvalidoException extends PerfilException {
  const FormatoInvalidoException() : super('Formato de imagem inválido.');
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
  const InternalServerException()
    : super('Erro no servidor. Tente novamente.');
}
