const pool = require('../../config/database');

async function listar(req, res) {
  const usuarioId = req.usuario.id;
  const pagina = Math.max(1, parseInt(req.query.pagina) || 1);
  const porPagina = Math.min(50, Math.max(1, parseInt(req.query.porPagina) || 20));
  const offset = (pagina - 1) * porPagina;

  try {
    const [result, total, naoLidas] = await Promise.all([
      pool.query(
        `SELECT * FROM notificacoes
         WHERE para = $1
         ORDER BY criado_em DESC
         LIMIT $2 OFFSET $3`,
        [usuarioId, porPagina, offset]
      ),
      pool.query('SELECT COUNT(*) FROM notificacoes WHERE para = $1', [usuarioId]),
      pool.query('SELECT COUNT(*) FROM notificacoes WHERE para = $1 AND lida = false', [usuarioId]),
    ]);

    return res.json({
      data: result.rows.map(_format),
      meta: {
        total: parseInt(total.rows[0].count),
        naoLidas: parseInt(naoLidas.rows[0].count),
        pagina,
        porPagina,
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function marcarComoLida(req, res) {
  const { id } = req.params;
  const usuarioId = req.usuario.id;

  try {
    const result = await pool.query(
      `UPDATE notificacoes SET lida = true
       WHERE id = $1 AND para = $2
       RETURNING *`,
      [id, usuarioId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'NOTIFICACAO_NAO_ENCONTRADA', message: 'Notificação não encontrada.' });
    }

    return res.json({ data: _format(result.rows[0]) });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function marcarTodasComoLidas(req, res) {
  const usuarioId = req.usuario.id;

  try {
    await pool.query(
      'UPDATE notificacoes SET lida = true WHERE para = $1 AND lida = false',
      [usuarioId]
    );

    return res.status(204).send();
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function contarNaoLidas(req, res) {
  const usuarioId = req.usuario.id;

  try {
    const result = await pool.query(
      'SELECT COUNT(*) FROM notificacoes WHERE para = $1 AND lida = false',
      [usuarioId]
    );

    return res.json({ data: { naoLidas: parseInt(result.rows[0].count) } });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

function _format(n) {
  return {
    id: n.id,
    para: n.para,
    deId: n.de_id,
    de: n.de,
    deUsername: n.de_username,
    tipo: n.tipo,
    texto: n.texto,
    postId: n.post_id,
    chatId: n.chat_id,
    lida: n.lida,
    criadoEm: n.criado_em,
  };
}

module.exports = { listar, marcarComoLida, marcarTodasComoLidas, contarNaoLidas };