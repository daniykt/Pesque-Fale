sealed class ClimaException implements Exception {
  const ClimaException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ClimaRedeException extends ClimaException {
  const ClimaRedeException()
    : super('Sem conexão para buscar o clima. Verifique a internet.');
}

class ClimaServicoException extends ClimaException {
  const ClimaServicoException()
    : super('O serviço de clima não respondeu. Tente de novo em instantes.');
}
