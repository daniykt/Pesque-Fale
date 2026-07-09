const pool = require('../../config/database');

async function criar(req, res) {
  const organizadorId = req.usuario.id;
  const { titulo, descricao, pontoId, dataInicio, dataFim, imagemUrl, localTexto } = req.body;

  if (!titulo || titulo.length < 2) {
    return res.status(400).json({
      error: 'VALIDATION_ERROR',
      message: 'Verifique os campos.',
      details: [{ campo: 'titulo', mensagem: 'Título deve ter pelo menos 2 caracteres.' }],
    });
  }

  if (!dataInicio) {
    return res.status(400).json({
      error: 'VALIDATION_ERROR',
      message: 'Verifique os campos.',
      details: [{ campo: 'dataInicio', mensagem: 'Data de início é obrigatória.' }],
    });
  }

  try {
    const result = await pool.query(
      `INSERT INTO eventos (titulo, descricao, ponto_id, organizador_id, data_inicio, data_fim, imagem_url, local_texto)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [titulo, descricao ?? null, pontoId ?? null, organizadorId,
       dataInicio, dataFim ?? null, imagemUrl ?? null, localTexto ?? null]
    );

    return res.status(201).json({ data: _format(result.rows[0]) });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function listar(req, res) {
  const pagina = Math.max(1, parseInt(req.query.pagina) || 1);
  const porPagina = Math.min(50, Math.max(1, parseInt(req.query.porPagina) || 20));
  const offset = (pagina - 1) * porPagina;
  const { futuros } = req.query;

  const conditions = [];
  const values = [];
  let i = 1;

  if (futuros === 'true') {
    conditions.push(`data_inicio >= NOW()`);
  }

  const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  try {
    const [result, total] = await Promise.all([
      pool.query(
        `SELECT e.*, u.nome AS organizador_nome, u.username AS organizador_username,
                u.foto_perfil AS organizador_foto
         FROM eventos e
         JOIN usuarios u ON u.id = e.organizador_id
         ${where}
         ORDER BY e.data_inicio DESC
         LIMIT $${i++} OFFSET $${i++}`,
        [...values, porPagina, offset]
      ),
      pool.query(`SELECT COUNT(*) FROM eventos ${where}`, values),
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

async function buscarPorId(req, res) {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `SELECT e.*, u.nome AS organizador_nome, u.username AS organizador_username,
              u.foto_perfil AS organizador_foto
       FROM eventos e
       JOIN usuarios u ON u.id = e.organizador_id
       WHERE e.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'EVENTO_NAO_ENCONTRADO', message: 'Evento não encontrado.' });
    }

    return res.json({ data: _format(result.rows[0]) });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function atualizar(req, res) {
  const { id } = req.params;
  const usuarioId = req.usuario.id;

  try {
    const existe = await pool.query('SELECT organizador_id FROM eventos WHERE id = $1', [id]);
    if (existe.rows.length === 0) {
      return res.status(404).json({ error: 'EVENTO_NAO_ENCONTRADO', message: 'Evento não encontrado.' });
    }
    if (existe.rows[0].organizador_id !== usuarioId) {
      return res.status(403).json({ error: 'FORBIDDEN', message: 'Você não tem permissão para editar este evento.' });
    }

    const { titulo, descricao, pontoId, dataInicio, dataFim, imagemUrl, localTexto } = req.body;
    const fields = [];
    const values = [];
    let i = 1;

    if (titulo !== undefined) { fields.push(`titulo = $${i++}`); values.push(titulo); }
    if (descricao !== undefined) { fields.push(`descricao = $${i++}`); values.push(descricao); }
    if (pontoId !== undefined) { fields.push(`ponto_id = $${i++}`); values.push(pontoId); }
    if (dataInicio !== undefined) { fields.push(`data_inicio = $${i++}`); values.push(dataInicio); }
    if (dataFim !== undefined) { fields.push(`data_fim = $${i++}`); values.push(dataFim); }
    if (imagemUrl !== undefined) { fields.push(`imagem_url = $${i++}`); values.push(imagemUrl); }
    if (localTexto !== undefined) { fields.push(`local_texto = $${i++}`); values.push(localTexto); }

    if (fields.length === 0) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Nenhum campo para atualizar.' });
    }

    fields.push(`atualizado_em = NOW()`);
    values.push(id);

    const result = await pool.query(
      `UPDATE eventos SET ${fields.join(', ')} WHERE id = $${i} RETURNING *`,
      values
    );

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
    const existe = await pool.query('SELECT organizador_id FROM eventos WHERE id = $1', [id]);
    if (existe.rows.length === 0) {
      return res.status(404).json({ error: 'EVENTO_NAO_ENCONTRADO', message: 'Evento não encontrado.' });
    }
    if (existe.rows[0].organizador_id !== usuarioId) {
      return res.status(403).json({ error: 'FORBIDDEN', message: 'Você não tem permissão para deletar este evento.' });
    }

    await pool.query('DELETE FROM eventos WHERE id = $1', [id]);
    return res.status(204).send();
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

function _format(e) {
  return {
    id: e.id,
    titulo: e.titulo,
    descricao: e.descricao,
    pontoId: e.ponto_id,
    organizadorId: e.organizador_id,
    organizadorNome: e.organizador_nome ?? undefined,
    organizadorUsername: e.organizador_username ?? undefined,
    organizadorFoto: e.organizador_foto ?? undefined,
    dataInicio: e.data_inicio,
    dataFim: e.data_fim,
    imagemUrl: e.imagem_url,
    localTexto: e.local_texto,
    criadoEm: e.criado_em,
    atualizadoEm: e.atualizado_em,
  };
}

module.exports = { criar, listar, buscarPorId, atualizar, deletar };