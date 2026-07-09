const { Router } = require('express');
const pool = require('../../config/database');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router();

// Listar conversas do usuário autenticado
router.get('/', authMiddleware, async (req, res) => {
  const usuarioId = req.usuario.id;

  try {
    const result = await pool.query(
      `SELECT c.id, c.criado_em,
        CASE WHEN c.participante_a = $1 THEN c.participante_b ELSE c.participante_a END AS outro_id,
        u.nome AS outro_nome, u.username AS outro_username, u.foto_perfil AS outro_foto,
        (SELECT texto FROM mensagens WHERE chat_id = c.id ORDER BY criado_em DESC LIMIT 1) AS ultima_mensagem,
        (SELECT criado_em FROM mensagens WHERE chat_id = c.id ORDER BY criado_em DESC LIMIT 1) AS ultima_mensagem_em,
        (SELECT COUNT(*) FROM mensagens WHERE chat_id = c.id AND user_id != $1 AND status = 'enviado') AS nao_lidas
       FROM chats c
       JOIN usuarios u ON u.id = CASE WHEN c.participante_a = $1 THEN c.participante_b ELSE c.participante_a END
       WHERE c.participante_a = $1 OR c.participante_b = $1
       ORDER BY ultima_mensagem_em DESC NULLS LAST`,
      [usuarioId]
    );

    return res.json({
      data: result.rows.map(c => ({
        id: c.id,
        outroId: c.outro_id,
        outroNome: c.outro_nome,
        outroUsername: c.outro_username,
        outroFoto: c.outro_foto,
        ultimaMensagem: c.ultima_mensagem,
        ultimaMensagemEm: c.ultima_mensagem_em,
        naoLidas: parseInt(c.nao_lidas),
        criadoEm: c.criado_em,
      })),
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
});

// Histórico de mensagens de um chat via REST (fallback)
router.get('/:chatId/mensagens', authMiddleware, async (req, res) => {
  const { chatId } = req.params;
  const usuarioId = req.usuario.id;
  const pagina = Math.max(1, parseInt(req.query.pagina) || 1);
  const porPagina = Math.min(100, Math.max(1, parseInt(req.query.porPagina) || 50));
  const offset = (pagina - 1) * porPagina;

  try {
    const chatExiste = await pool.query(
      'SELECT id FROM chats WHERE id = $1 AND (participante_a = $2 OR participante_b = $2)',
      [chatId, usuarioId]
    );

    if (chatExiste.rows.length === 0) {
      return res.status(404).json({ error: 'CHAT_NAO_ENCONTRADO', message: 'Chat não encontrado.' });
    }

    const [result, total] = await Promise.all([
      pool.query(
        `SELECT * FROM mensagens WHERE chat_id = $1
         ORDER BY criado_em ASC
         LIMIT $2 OFFSET $3`,
        [chatId, porPagina, offset]
      ),
      pool.query('SELECT COUNT(*) FROM mensagens WHERE chat_id = $1', [chatId]),
    ]);

    return res.json({
      data: result.rows.map(m => ({
        id: m.id,
        chatId: m.chat_id,
        userId: m.user_id,
        nome: m.nome,
        texto: m.texto,
        status: m.status,
        criadoEm: m.criado_em,
      })),
      meta: {
        total: parseInt(total.rows[0].count),
        pagina,
        porPagina,
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
});

module.exports = router;