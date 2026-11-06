const pool = require('../../config/database');
const { criarNotificacao } = require('../notificacoes/notificacoes.helper');
const { emitToFeed } = require('../../config/socket-emitter');

async function listar(req, res) {
  const { publicacaoId } = req.params;
  const pagina = Math.max(1, parseInt(req.query.pagina) || 1);
  const porPagina = Math.min(50, Math.max(1, parseInt(req.query.porPagina) || 20));
  const offset = (pagina - 1) * porPagina;

  try {
    const [result, total] = await Promise.all([
      pool.query(
        `SELECT c.id, c.publicacao_id, c.autor_id, c.texto, c.criado_em,
                u.nome AS autor_nome, u.username AS autor_username, u.foto_perfil AS autor_foto
         FROM comentarios c
         JOIN usuarios u ON u.id = c.autor_id
         WHERE c.publicacao_id = $1
         ORDER BY c.criado_em DESC
         LIMIT $2 OFFSET $3`,
        [publicacaoId, porPagina, offset]
      ),
      pool.query('SELECT COUNT(*) FROM comentarios WHERE publicacao_id = $1', [publicacaoId]),
    ]);

    return res.json({
      data: result.rows.map(_format),
      meta: { total: parseInt(total.rows[0].count), pagina, porPagina },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function criar(req, res) {
  const { publicacaoId } = req.params;
  const autorId = req.usuario.id;
  const { texto } = req.body;

  if (!texto || texto.length < 1 || texto.length > 500) {
    return res.status(400).json({
      error: 'VALIDATION_ERROR',
      message: 'Verifique os campos.',
      details: [{ campo: 'texto', mensagem: 'Texto deve ter entre 1 e 500 caracteres.' }],
    });
  }

  try {
    // Uma ida ao banco: insere e já devolve o comentário com os dados do autor
    // e o autor da publicação (para a notificação). Publicação inexistente
    // dispara a FK (23503) aqui dentro.
    const result = await pool.query(
      `WITH ins AS (
         INSERT INTO comentarios (publicacao_id, autor_id, texto) VALUES ($1, $2, $3)
         RETURNING id, publicacao_id, autor_id, texto, criado_em
       )
       SELECT ins.*, u.nome AS autor_nome, u.username AS autor_username, u.foto_perfil AS autor_foto,
              p.autor_id AS publicacao_autor_id, p.comentarios_count
       FROM ins
       JOIN usuarios u ON u.id = ins.autor_id
       JOIN publicacoes p ON p.id = ins.publicacao_id`,
      [publicacaoId, autorId, texto]
    );

    const comentario = result.rows[0];
    emitirComentarios(publicacaoId, comentario.comentarios_count + 1, autorId);

    await criarNotificacao({
      para: comentario.publicacao_autor_id,
      deId: autorId,
      tipo: 'comentario',
      texto: texto.slice(0, 100),
      postId: publicacaoId,
    });

    return res.status(201).json({ data: _format(comentario) });
  } catch (err) {
    if (err.code === '23503') {
      return res.status(404).json({ error: 'PUBLICACAO_NAO_ENCONTRADA', message: 'Publicação não encontrada.' });
    }
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function deletar(req, res) {
  const { id } = req.params;
  const usuarioId = req.usuario.id;

  try {
    const existe = await pool.query(
      `SELECT c.autor_id, c.publicacao_id, p.comentarios_count
       FROM comentarios c
       JOIN publicacoes p ON p.id = c.publicacao_id
       WHERE c.id = $1`,
      [id]
    );
    if (existe.rows.length === 0) {
      return res.status(404).json({ error: 'COMENTARIO_NAO_ENCONTRADO', message: 'Comentário não encontrado.' });
    }
    if (existe.rows[0].autor_id !== usuarioId) {
      return res.status(403).json({ error: 'FORBIDDEN', message: 'Você não tem permissão para deletar este comentário.' });
    }

    await pool.query('DELETE FROM comentarios WHERE id = $1', [id]);

    const { publicacao_id: publicacaoId, comentarios_count: atual } = existe.rows[0];
    emitirComentarios(publicacaoId, Math.max(atual - 1, 0), usuarioId);

    return res.status(204).send();
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

function emitirComentarios(publicacaoId, comentariosCount, porId) {
  try {
    emitToFeed('publicacao_comentarios', { publicacaoId, comentariosCount, porId });
  } catch (err) {
    console.error('[comentarios] erro ao emitir publicacao_comentarios:', err);
  }
}

function _format(c) {
  return {
    id: c.id,
    publicacaoId: c.publicacao_id,
    autorId: c.autor_id,
    autorNome: c.autor_nome ?? undefined,
    autorUsername: c.autor_username ?? undefined,
    autorFoto: c.autor_foto ?? undefined,
    texto: c.texto,
    criadoEm: c.criado_em,
  };
}

module.exports = { listar, criar, deletar };