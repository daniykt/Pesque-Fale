const pool = require('../../config/database');
const { criarNotificacao } = require('../notificacoes/notificacoes.helper');

async function curtir(req, res) {
  const { publicacaoId } = req.params;
  const usuarioId = req.usuario.id;

  try {
    await pool.query(
      'INSERT INTO curtidas (usuario_id, publicacao_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [usuarioId, publicacaoId]
    );

    const publicacao = await pool.query(
      'SELECT autor_id FROM publicacoes WHERE id = $1',
      [publicacaoId]
    );

    if (publicacao.rows.length > 0) {
      await criarNotificacao({
        para: publicacao.rows[0].autor_id,
        deId: usuarioId,
        tipo: 'curtida',
        postId: publicacaoId,
      });
    }

    return res.status(201).json({ data: { curtido: true } });
  } catch (err) {
    if (err.code === '23503') {
      return res.status(404).json({ error: 'PUBLICACAO_NAO_ENCONTRADA', message: 'Publicação não encontrada.' });
    }
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function descurtir(req, res) {
  const { publicacaoId } = req.params;
  const usuarioId = req.usuario.id;

  try {
    await pool.query('DELETE FROM curtidas WHERE usuario_id = $1 AND publicacao_id = $2', [usuarioId, publicacaoId]);
    return res.status(200).json({ data: { curtido: false } });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

module.exports = { curtir, descurtir };