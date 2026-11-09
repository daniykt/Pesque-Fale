sealed class EventosException implements Exception {
  const EventosException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EventoNaoEncontradoException extends EventosException {
  const EventoNaoEncontradoException() : super('Evento não encontrado.');
}

class EventoSemPermissaoException extends EventosException {
  const EventoSemPermissaoException()
    : super('Só quem organizou o evento pode alterá-lo.');
}

class EventoNaoAutenticadoException extends EventosException {
  const EventoNaoAutenticadoException()
    : super('Entre na sua conta para criar ou alterar eventos.');
}

class EventoValidacaoException extends EventosException {
  EventoValidacaoException(this.errosPorCampo)
    : super(
        errosPorCampo.values.isNotEmpty
            ? errosPorCampo.values.first
            : 'Verifique os campos e tente novamente.',
      );

  final Map<String, String> errosPorCampo;
}

class EventosRedeException extends EventosException {
  const EventosRedeException() : super('Sem conexão com o servidor.');
}

class EventosServidorException extends EventosException {
  const EventosServidorException()
    : super('Erro no servidor. Tente novamente.');
}
