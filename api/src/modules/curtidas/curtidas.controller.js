const pool = require('../../config/database');
const { criarNotificacao } = require('../notificacoes/notificacoes.helper');
const { emitToFeed } = require('../../config/socket-emitter');

async function curtir(req, res) {
  const { publicacaoId } = req.params;
  const usuarioId = req.usuario.id;

  try {
    // Uma ida ao banco: insere a curtida e devolve o autor da publicação e se
    // a curtida é nova. Publicação inexistente dispara a FK (23503) aqui dentro.
    const result = await pool.query(
      `WITH ins AS (
         INSERT INTO curtidas (usuario_id, publicacao_id) VALUES ($1, $2)
         ON CONFLICT DO NOTHING
         RETURNING publicacao_id
       )
       SELECT p.autor_id, p.curtidas_count, EXISTS (SELECT 1 FROM ins) AS nova
       FROM publicacoes p WHERE p.id = $2`,
      [usuarioId, publicacaoId]
    );

    // Só notifica curtida nova. Curtir de novo (toque duplo, retry de rede) é
    // idempotente e silencioso, no mesmo padrão do seguir.
    const publicacao = result.rows[0];
    if (publicacao && publicacao.nova === true) {
      emitirCurtidas(publicacaoId, publicacao.curtidas_count + 1, usuarioId);
      await criarNotificacao({
        para: publicacao.autor_id,
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
    const result = await pool.query(
      `WITH del AS (
         DELETE FROM curtidas WHERE usuario_id = $1 AND publicacao_id = $2
         RETURNING publicacao_id
       )
       SELECT p.curtidas_count, EXISTS (SELECT 1 FROM del) AS removida
       FROM publicacoes p WHERE p.id = $2`,
      [usuarioId, publicacaoId]
    );

    const publicacao = result.rows[0];
    if (publicacao && publicacao.removida === true) {
      emitirCurtidas(publicacaoId, Math.max(publicacao.curtidas_count - 1, 0), usuarioId);
    }

    return res.status(200).json({ data: { curtido: false } });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

function emitirCurtidas(publicacaoId, curtidasCount, porId) {
  try {
    emitToFeed('publicacao_curtidas', { publicacaoId, curtidasCount, porId });
  } catch (err) {
    console.error('[curtidas] erro ao emitir publicacao_curtidas:', err);
  }
}

module.exports = { curtir, descurtir };