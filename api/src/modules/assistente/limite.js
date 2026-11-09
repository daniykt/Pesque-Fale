const MAXIMO_POR_JANELA = 20;
const JANELA_MS = 60 * 60 * 1000;

const usos = new Map();

function consumir(usuarioId, agora = Date.now()) {
  const recentes = (usos.get(usuarioId) ?? []).filter(
    (momento) => agora - momento < JANELA_MS
  );

  if (recentes.length >= MAXIMO_POR_JANELA) {
    usos.set(usuarioId, recentes);
    return false;
  }

  recentes.push(agora);
  usos.set(usuarioId, recentes);
  return true;
}

function limparLimites() {
  usos.clear();
}

module.exports = { MAXIMO_POR_JANELA, consumir, limparLimites };