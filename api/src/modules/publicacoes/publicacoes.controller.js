const pool = require('../../config/database');

async function listarPorUsuario(req, res) {
  const { id } = req.params;
  const pagina = Math.max(1, parseInt(req.query.pagina) || 1);
  const porPagina = Math.min(48, Math.max(1, parseInt(req.query.porPagina) || 12));
  const offset = (pagina - 1) * porPagina;

  try {
    const usuarioExiste = await pool.query('SELECT id FROM usuarios WHERE id = $1', [id]);
    if (usuarioExiste.rows.length === 0) {
      return res.status(404).json({ error: 'USUARIO_NAO_ENCONTRADO', message: 'Usuário não encontrado.' });
    }

    const [result, total] = await Promise.all([
      pool.query(
        `SELECT id, autor_id, ponto_id, descricao, imagem_url, local_texto,
                avaliacao_nota, curtidas_count, comentarios_count, criado_em, atualizado_em
         FROM publicacoes
         WHERE autor_id = $1
         ORDER BY criado_em DESC
         LIMIT $2 OFFSET $3`,
        [id, porPagina, offset]
      ),
      pool.query('SELECT COUNT(*) FROM publicacoes WHERE autor_id = $1', [id]),
    ]);

    return res.json({
      data: result.rows.map(_format),
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
}

async function criar(req, res) {
  const autorId = req.usuario.id;
  const { descricao, imagemUrl, localTexto, avaliacaoNota, pontoId } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO publicacoes (autor_id, ponto_id, descricao, imagem_url, local_texto, avaliacao_nota)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [autorId, pontoId ?? null, descricao ?? null, imagemUrl ?? null, localTexto ?? null, avaliacaoNota ?? null]
    );

    return res.status(201).json({ data: _format(result.rows[0]) });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function buscarPorId(req, res) {
  const { id } = req.params;

  try {
    const result = await pool.query('SELECT * FROM publicacoes WHERE id = $1', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'PUBLICACAO_NAO_ENCONTRADA', message: 'Publicação não encontrada.' });
    }
    return res.json({ data: _format(result.rows[0]) });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function deletar(req, res) {
  const { id } = req.params;
  const usuarioId = req.usuario.id;

  try {
    const existe = await pool.query('SELECT autor_id FROM publicacoes WHERE id = $1', [id]);
    if (existe.rows.length === 0) {
      return res.status(404).json({ error: 'PUBLICACAO_NAO_ENCONTRADA', message: 'Publicação não encontrada.' });
    }
    if (existe.rows[0].autor_id !== usuarioId) {
      return res.status(403).json({ error: 'FORBIDDEN', message: 'Você não tem permissão para deletar esta publicação.' });
    }

    await pool.query('DELETE FROM publicacoes WHERE id = $1', [id]);
    return res.status(204).send();
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

function _format(p) {
  return {
    id: p.id,
    autorId: p.autor_id,
    pontoId: p.ponto_id,
    descricao: p.descricao,
    imagemUrl: p.imagem_url,
    localTexto: p.local_texto,
    avaliacaoNota: p.avaliacao_nota ? parseFloat(p.avaliacao_nota) : null,
    curtidasCount: p.curtidas_count,
    comentariosCount: p.comentarios_count,
    criadoEm: p.criado_em,
    atualizadoEm: p.atualizado_em,
  };
}

module.exports = { listarPorUsuario, criar, buscarPorId, deletar };
