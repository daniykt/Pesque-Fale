const pool = require('../../config/database');

async function criar(req, res) {
  const { nota, comentario } = req.body;
  const usuarioId = req.usuario.id;
  const { pontoId } = req.params;

  const details = [];
  if (nota === undefined || nota === null) {
    details.push({ campo: 'nota', mensagem: 'Nota é obrigatória.' });
  } else if (nota < 1 || nota > 5) {
    details.push({ campo: 'nota', mensagem: 'Nota deve ser entre 1 e 5.' });
  }

  if (details.length > 0) {
    return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Verifique os campos.', details });
  }

  try {
    const pontoExiste = await pool.query('SELECT id FROM pontos_de_pesca WHERE id = $1', [pontoId]);
    if (pontoExiste.rows.length === 0) {
      return res.status(404).json({ error: 'PONTO_NAO_ENCONTRADO', message: 'Ponto de pesca não encontrado.' });
    }

    const result = await pool.query(
      `INSERT INTO avaliacoes (usuario_id, ponto_id, nota, comentario)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [usuarioId, pontoId, nota, comentario ?? null]
    );

    return res.status(201).json({ data: _format(result.rows[0]) });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({
        error: 'AVALIACAO_JA_EXISTE',
        message: 'Você já avaliou este ponto. Use PATCH para atualizar.',
      });
    }
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function listar(req, res) {
  const { pontoId } = req.params;
  const pagina = Math.max(1, parseInt(req.query.pagina) || 1);
  const porPagina = Math.min(50, Math.max(1, parseInt(req.query.porPagina) || 20));
  const offset = (pagina - 1) * porPagina;

  try {
    const pontoExiste = await pool.query('SELECT id FROM pontos_de_pesca WHERE id = $1', [pontoId]);
    if (pontoExiste.rows.length === 0) {
      return res.status(404).json({ error: 'PONTO_NAO_ENCONTRADO', message: 'Ponto de pesca não encontrado.' });
    }

    const [result, total] = await Promise.all([
      pool.query(
        `SELECT a.*, u.nome AS usuario_nome, u.username AS usuario_username, u.foto_perfil AS usuario_foto
         FROM avaliacoes a
         JOIN usuarios u ON u.id = a.usuario_id
         WHERE a.ponto_id = $1
         ORDER BY a.criado_em DESC
         LIMIT $2 OFFSET $3`,
        [pontoId, porPagina, offset]
      ),
      pool.query('SELECT COUNT(*) FROM avaliacoes WHERE ponto_id = $1', [pontoId]),
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

async function buscarMinha(req, res) {
  const { pontoId } = req.params;
  const usuarioId = req.usuario.id;

  try {
    const result = await pool.query(
      'SELECT * FROM avaliacoes WHERE ponto_id = $1 AND usuario_id = $2',
      [pontoId, usuarioId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'AVALIACAO_NAO_ENCONTRADA', message: 'Você ainda não avaliou este ponto.' });
    }

    return res.json({ data: _format(result.rows[0]) });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function atualizar(req, res) {
  const { pontoId } = req.params;
  const usuarioId = req.usuario.id;
  const { nota, comentario } = req.body;

  if (nota !== undefined && (nota < 1 || nota > 5)) {
    return res.status(400).json({
      error: 'VALIDATION_ERROR',
      message: 'Verifique os campos.',
      details: [{ campo: 'nota', mensagem: 'Nota deve ser entre 1 e 5.' }],
    });
  }

  try {
    const existe = await pool.query(
      'SELECT id FROM avaliacoes WHERE ponto_id = $1 AND usuario_id = $2',
      [pontoId, usuarioId]
    );

    if (existe.rows.length === 0) {
      return res.status(404).json({ error: 'AVALIACAO_NAO_ENCONTRADA', message: 'Avaliação não encontrada.' });
    }

    const fields = [];
    const values = [];
    let i = 1;

    if (nota !== undefined) { fields.push(`nota = $${i++}`); values.push(nota); }
    if (comentario !== undefined) { fields.push(`comentario = $${i++}`); values.push(comentario); }

    if (fields.length === 0) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Nenhum campo para atualizar.' });
    }

    fields.push(`atualizado_em = NOW()`);
    values.push(pontoId, usuarioId);

    const result = await pool.query(
      `UPDATE avaliacoes SET ${fields.join(', ')}
       WHERE ponto_id = $${i++} AND usuario_id = $${i++}
       RETURNING *`,
      values
    );

    return res.json({ data: _format(result.rows[0]) });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function deletar(req, res) {
  const { pontoId } = req.params;
  const usuarioId = req.usuario.id;

  try {
    const result = await pool.query(
      'DELETE FROM avaliacoes WHERE ponto_id = $1 AND usuario_id = $2 RETURNING id',
      [pontoId, usuarioId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'AVALIACAO_NAO_ENCONTRADA', message: 'Avaliação não encontrada.' });
    }

    return res.status(204).send();
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

function _format(a) {
  return {
    id: a.id,
    usuarioId: a.usuario_id,
    usuarioNome: a.usuario_nome ?? undefined,
    usuarioUsername: a.usuario_username ?? undefined,
    usuarioFoto: a.usuario_foto ?? undefined,
    pontoId: a.ponto_id,
    nota: parseFloat(a.nota),
    comentario: a.comentario,
    criadoEm: a.criado_em,
    atualizadoEm: a.atualizado_em,
  };
}

module.exports = { criar, listar, buscarMinha, atualizar, deletar };