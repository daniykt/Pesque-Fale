const jwt = require('jsonwebtoken');
const pool = require('../../config/database');
const { emitToUser } = require('../../config/socket-emitter');

function gerarChatId(uid1, uid2) {
  return [uid1, uid2].sort().join('_');
}

async function verificarMutualFollow(uid1, uid2) {
  const result = await pool.query(
    `SELECT EXISTS (SELECT 1 FROM usuario_seguidores WHERE seguidor_id = $1 AND seguido_id = $2)
        AND EXISTS (SELECT 1 FROM usuario_seguidores WHERE seguidor_id = $2 AND seguido_id = $1) AS mutuo`,
    [uid1, uid2]
  );
  return result.rows[0].mutuo;
}

async function obterOuCriarChat(uid1, uid2) {
  const chatId = gerarChatId(uid1, uid2);
  const [a, b] = [uid1, uid2].sort();

  await pool.query(
    `INSERT INTO chats (id, participante_a, participante_b)
     VALUES ($1, $2, $3)
     ON CONFLICT (id) DO NOTHING`,
    [chatId, a, b]
  );

  return chatId;
}

async function salvarMensagem(chatId, userId, nome, texto) {
  const result = await pool.query(
    `INSERT INTO mensagens (chat_id, user_id, nome, texto)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [chatId, userId, nome, texto]
  );
  return result.rows[0];
}

async function contarMensagens(chatId) {
  const result = await pool.query(
    'SELECT COUNT(*) FROM mensagens WHERE chat_id = $1',
    [chatId]
  );
  return parseInt(result.rows[0].count, 10);
}

async function buscarDadosRemetente(userId) {
  const result = await pool.query(
    'SELECT id, nome, username, foto_perfil FROM usuarios WHERE id = $1',
    [userId]
  );
  return result.rows[0] ?? null;
}

async function marcarComoVistas(chatId, userId) {
  await pool.query(
    `UPDATE mensagens SET status = 'visto'
     WHERE chat_id = $1 AND user_id != $2 AND status = 'enviado'`,
    [chatId, userId]
  );
}

// Avisa os rooms pessoais dos dois participantes que `leitorId` leu a
// conversa. Roda depois do UPDATE de marcarComoVistas: falha aqui é só log.
function emitirConversaLida(chatId, leitorId) {
  try {
    const [a, b] = chatId.split('_');
    const outroId = a === leitorId ? b : a;
    const payload = {
      conversaId: chatId,
      lidaPor: leitorId,
      quandoEm: new Date().toISOString(),
    };
    // O leitor zera o próprio badge (em todos os dispositivos); o outro
    // participante recebe e ignora no app.
    emitToUser(leitorId, 'conversa_lida', payload);
    emitToUser(outroId, 'conversa_lida', payload);
  } catch (err) {
    console.error('[chat] erro pós-update ao emitir conversa_lida:', err);
  }
}

module.exports = function initChatGateway(io) {
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) return next(new Error('TOKEN_INVALIDO'));

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.usuario = decoded;
      next();
    } catch {
      next(new Error('TOKEN_INVALIDO'));
    }
  });

  io.on('connection', (socket) => {
    const usuarioId = socket.usuario.id;
    console.log(`Socket conectado: ${usuarioId}`);
    socket.join(`user:${usuarioId}`);

    // Entrar em uma sala de chat
    socket.on('entrar_chat', async ({ outroId }) => {
      try {
        if (outroId === usuarioId) {
          socket.emit('erro', { code: 'CHAT_CONSIGO_MESMO', message: 'Não é possível conversar consigo mesmo.' });
          return;
        }

        const mutuo = await verificarMutualFollow(usuarioId, outroId);
        if (!mutuo) {
          socket.emit('erro', { message: 'Vocês precisam se seguir mutuamente para conversar.' });
          return;
        }

        const chatId = await obterOuCriarChat(usuarioId, outroId);
        socket.join(chatId);
        socket.chatId = chatId;
        socket.outroId = outroId;

        // Marcar mensagens como vistas ao entrar
        await marcarComoVistas(chatId, usuarioId);

        // Buscar histórico
        const historico = await pool.query(
          `SELECT * FROM mensagens
           WHERE chat_id = $1
           ORDER BY criado_em ASC
           LIMIT 50`,
          [chatId]
        );

        socket.emit('historico', {
          chatId,
          mensagens: historico.rows.map(_formatMensagem),
        });

        io.to(chatId).emit('mensagens_vistas', { chatId, porId: usuarioId });
        // Abrir a conversa já marcou tudo como visto acima: avisa o inbox.
        emitirConversaLida(chatId, usuarioId);
      } catch (err) {
        console.error(err);
        socket.emit('erro', { message: 'Erro ao entrar no chat.' });
      }
    });

    // Enviar mensagem
    socket.on('enviar_mensagem', async ({ texto }) => {
      if (!socket.chatId || !texto?.trim()) return;

      let mensagem;
      try {
        const usuario = await pool.query(
          'SELECT nome FROM usuarios WHERE id = $1',
          [usuarioId]
        );
        const nome = usuario.rows[0]?.nome ?? 'Usuário';

        mensagem = await salvarMensagem(socket.chatId, usuarioId, nome, texto.trim());
      } catch (err) {
        console.error(err);
        socket.emit('erro', { message: 'Erro ao enviar mensagem.' });
        return;
      }

      // A partir daqui a mensagem já está no banco. Qualquer falha é problema
      // operacional (log) — NÃO emite 'erro' pro cliente, que veria como não
      // enviada uma mensagem persistida.

      // Descobre o destinatário a partir do chatId (formato "<uidA>_<uidB>" ordenado).
      const [a, b] = socket.chatId.split('_');
      const destinatarioId = a === usuarioId ? b : a;

      try {
        // Calcula se é a primeira mensagem do chat (count ANTES deste insert = 0,
        // agora = 1 — já que o insert aconteceu acima).
        const totalMensagens = await contarMensagens(socket.chatId);
        const primeiraMensagem = totalMensagens === 1;

        if (primeiraMensagem) {
          const remetente = await buscarDadosRemetente(usuarioId);
          if (remetente) {
            const payloadNovaConversa = {
              conversaId: socket.chatId,
              remetente: {
                id: remetente.id,
                nome: remetente.nome,
                username: remetente.username,
                fotoUrl: remetente.foto_perfil,
              },
              ultimaMensagem: _formatMensagem(mensagem),
            };
            // Emite pro destinatário E pro próprio remetente — ambos precisam ver
            // a nova conversa aparecer na lista (o remetente também mantém uma
            // lista de conversas na aba Chat).
            emitToUser(destinatarioId, 'nova_conversa', payloadNovaConversa);
            emitToUser(usuarioId, 'nova_conversa', payloadNovaConversa);
          }
        }
      } catch (err) {
        console.error('[chat] erro pós-insert, mensagem já salva:', err);
      }

      // Try próprio: falha ao detectar a 1ª mensagem não pode impedir o preview.
      try {
        // Sempre emite pros dois lados pra manter a lista de conversas sincronizada.
        const payloadPreview = {
          conversaId: socket.chatId,
          previewTexto: mensagem.texto,
          timestamp: mensagem.criado_em,
          remetenteId: usuarioId,
        };
        emitToUser(destinatarioId, 'nova_mensagem_em_conversa', payloadPreview);
        emitToUser(usuarioId, 'nova_mensagem_em_conversa', payloadPreview);
      } catch (err) {
        console.error('[chat] erro pós-insert, mensagem já salva:', err);
      }

      // Sempre dispara, mesmo se os emits globais acima falharam: é o retorno
      // de sucesso pra tela de chat aberta.
      io.to(socket.chatId).emit('nova_mensagem', _formatMensagem(mensagem));
    });

    // Marcar como visto
    socket.on('marcar_visto', async () => {
      if (!socket.chatId) return;
      try {
        await marcarComoVistas(socket.chatId, usuarioId);
      } catch (err) {
        console.error(err);
        return; // DB falhou — nada a emitir
      }

      // UPDATE commitou. Qualquer falha de emit daqui pra frente é só log,
      // seguindo o padrão do erro pós-insert de enviar_mensagem.
      io.to(socket.chatId).emit('mensagens_vistas', { chatId: socket.chatId, porId: usuarioId });
      emitirConversaLida(socket.chatId, usuarioId);
    });

    // Indicador de digitação
    socket.on('digitando', () => {
      if (!socket.chatId) return;
      socket.to(socket.chatId).emit('outro_digitando', { userId: usuarioId });
    });

    // Indicador de parou de digitar
    socket.on('parou_digitando', () => {
      if (!socket.chatId) return;
      socket.to(socket.chatId).emit('outro_parou_digitando', { userId: usuarioId });
    });

    socket.on('disconnect', () => {
      console.log(`Socket desconectado: ${usuarioId}`);
    });
  });
};

function _formatMensagem(m) {
  return {
    id: m.id,
    chatId: m.chat_id,
    userId: m.user_id,
    nome: m.nome,
    texto: m.texto,
    status: m.status,
    criadoEm: m.criado_em,
  };
}

module.exports.verificarMutualFollow = verificarMutualFollow;