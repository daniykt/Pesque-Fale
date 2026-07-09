const jwt = require('jsonwebtoken');
const pool = require('../../config/database');

function gerarChatId(uid1, uid2) {
  return [uid1, uid2].sort().join('_');
}

async function verificarMutualFollow(uid1, uid2) {
  const result = await pool.query(
    `SELECT COUNT(*) FROM usuario_seguidores
     WHERE (seguidor_id = $1 AND seguido_id = $2)
        OR (seguidor_id = $2 AND seguido_id = $1)`,
    [uid1, uid2]
  );
  return parseInt(result.rows[0].count) === 2;
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

async function marcarComoVistas(chatId, userId) {
  await pool.query(
    `UPDATE mensagens SET status = 'visto'
     WHERE chat_id = $1 AND user_id != $2 AND status = 'enviado'`,
    [chatId, userId]
  );
}

async function criarNotificacaoMensagem(remetenteId, destinatarioId, chatId, texto) {
  try {
    const remetente = await pool.query(
      'SELECT nome, username FROM usuarios WHERE id = $1',
      [remetenteId]
    );
    if (remetente.rows.length === 0) return;

    const { nome, username } = remetente.rows[0];

    await pool.query(
      `INSERT INTO notificacoes
        (para, de_id, de, de_username, tipo, texto, chat_id)
       VALUES ($1, $2, $3, $4, 'mensagem', $5, $6)`,
      [destinatarioId, remetenteId, nome, username, texto.substring(0, 100), chatId]
    );
  } catch (err) {
    console.error('Erro ao criar notificação:', err);
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

    // Entrar em uma sala de chat
    socket.on('entrar_chat', async ({ outroId }) => {
      try {
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
      } catch (err) {
        console.error(err);
        socket.emit('erro', { message: 'Erro ao entrar no chat.' });
      }
    });

    // Enviar mensagem
    socket.on('enviar_mensagem', async ({ texto }) => {
      if (!socket.chatId || !texto?.trim()) return;

      try {
        const usuario = await pool.query(
          'SELECT nome FROM usuarios WHERE id = $1',
          [usuarioId]
        );
        const nome = usuario.rows[0]?.nome ?? 'Usuário';

        const mensagem = await salvarMensagem(socket.chatId, usuarioId, nome, texto.trim());

        io.to(socket.chatId).emit('nova_mensagem', _formatMensagem(mensagem));

        // Notificar destinatário
        if (socket.outroId) {
          await criarNotificacaoMensagem(usuarioId, socket.outroId, socket.chatId, texto.trim());
        }
      } catch (err) {
        console.error(err);
        socket.emit('erro', { message: 'Erro ao enviar mensagem.' });
      }
    });

    // Marcar como visto
    socket.on('marcar_visto', async () => {
      if (!socket.chatId) return;
      try {
        await marcarComoVistas(socket.chatId, usuarioId);
        io.to(socket.chatId).emit('mensagens_vistas', { chatId: socket.chatId, porId: usuarioId });
      } catch (err) {
        console.error(err);
      }
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