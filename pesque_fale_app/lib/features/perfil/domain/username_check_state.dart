enum UsernameCheckState {
  /// Vazio ou ainda não avaliado.
  idle,

  /// Aguardando a resposta de `GET /usuarios/username/:u`.
  validating,

  /// Não bate com `^[a-zA-Z0-9_.]{3,20}$`.
  invalidoFormato,

  /// A API confirmou que já está em uso.
  indisponivel,

  /// A API confirmou que está livre.
  disponivel,

  /// Igual ao username original do usuário — nada para checar.
  atual,
}
