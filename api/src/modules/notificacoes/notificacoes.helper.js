const pool = require('../../config/database');

async function criarNotificacao({ para, deId, tipo, texto, postId, chatId }) {
  try {
    if (para === deId) return; // não notifica a si mesmo

    const remetente = await pool.query(
      'SELECT nome, username FROM usuarios WHERE id = $1',
      [deId]
    );
    if (remetente.rows.length === 0) return;

    const { nome, username } = remetente.rows[0];

    await pool.query(
      `INSERT INTO notificacoes (para, de_id, de, de_username, tipo, texto, post_id, chat_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [para, deId, nome, username, tipo, texto ?? null, postId ?? null, chatId ?? null]
    );
  } catch (err) {
    console.error('Erro ao criar notificação:', err);
  }
}

module.exports = { criarNotificacao };