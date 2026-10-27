// Guarda a instância do Socket.IO pra qualquer módulo (ex.: controllers REST)
// emitir pra um usuário sem precisar receber `io` por parâmetro.
// Cada socket autenticado entra no room `user:<id>` no gateway; emitir pra
// esse room entrega em todos os dispositivos logados daquele usuário.

let io = null;

function init(instancia) {
  io = instancia;
}

function emitToUser(userId, evento, payload) {
  if (!io) {
    // Sem socket no ar, a request REST que chamou não pode quebrar por isso.
    console.warn(`[socket-emitter] emitToUser('${evento}') chamado antes de init(io) — ignorado.`);
    return;
  }
  io.to(`user:${userId}`).emit(evento, payload);
}

module.exports = { init, emitToUser };
