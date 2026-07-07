const pool = require('../../config/database');

const TIPOS_VALIDOS = ['pesqueiro', 'rio', 'lago', 'represa', 'mar'];

async function criar(req, res) {
  const { nome, descricao, latitude, longitude, cidade, estado, tipo, fotoCapa, fotos, tags } = req.body;
  const criado_por = req.usuario.id;

  const details = [];
  if (!nome || nome.length < 2) details.push({ campo: 'nome', mensagem: 'Nome deve ter pelo menos 2 caracteres.' });
  if (latitude === undefined || latitude === null) details.push({ campo: 'latitude', mensagem: 'Latitude é obrigatória.' });
  if (longitude === undefined || longitude === null) details.push({ campo: 'longitude', mensagem: 'Longitude é obrigatória.' });
  if (!cidade) details.push({ campo: 'cidade', mensagem: 'Cidade é obrigatória.' });
  if (!estado || estado.length !== 2) details.push({ campo: 'estado', mensagem: 'Estado deve ter 2 caracteres (UF).' });
  if (!tipo || !TIPOS_VALIDOS.includes(tipo)) details.push({ campo: 'tipo', mensagem: `Tipo deve ser: ${TIPOS_VALIDOS.join(', ')}.` });

  if (details.length > 0) {
    return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Verifique os campos.', details });
  }

  try {
    const result = await pool.query(
      `INSERT INTO pontos_de_pesca
        (nome, descricao, latitude, longitude, cidade, estado, tipo, foto_capa, fotos, tags, criado_por)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
       RETURNING *`,
      [nome, descricao ?? null, latitude, longitude, cidade, estado.toUpperCase(), tipo,
       fotoCapa ?? null, fotos ?? null, tags ?? null, criado_por]
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
  const { tipo, cidade, estado, busca } = req.query;
  const lat = parseFloat(req.query.lat);
  const lng = parseFloat(req.query.lng);
  const raio = parseFloat(req.query.raio) || 50;

  const conditions = [];
  const values = [];
  let i = 1;

  if (tipo) { conditions.push(`tipo = $${i++}`); values.push(tipo); }
  if (cidade) { conditions.push(`LOWER(cidade) = LOWER($${i++})`); values.push(cidade); }
  if (estado) { conditions.push(`estado = $${i++}`); values.push(estado.toUpperCase()); }
  if (busca) { conditions.push(`LOWER(nome) LIKE LOWER($${i++})`); values.push(`%${busca}%`); }

  let distanciaSelect = '';
  let orderBy = 'criado_em DESC';

  if (!isNaN(lat) && !isNaN(lng)) {
    distanciaSelect = `,
      ROUND((
        6371 * acos(
          cos(radians($${i})) * cos(radians(latitude)) *
          cos(radians(longitude) - radians($${i + 1})) +
          sin(radians($${i})) * sin(radians(latitude))
        )
      )::numeric, 1) AS distancia_km`;
    conditions.push(`(
      6371 * acos(
        cos(radians($${i})) * cos(radians(latitude)) *
        cos(radians(longitude) - radians($${i + 1})) +
        sin(radians($${i})) * sin(radians(latitude))
      )
    ) <= $${i + 2}`);
    values.push(lat, lng, raio);
    i += 3;
    orderBy = 'distancia_km ASC';
  }

  const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  try {
    const [result, total] = await Promise.all([
      pool.query(
        `SELECT id, nome, descricao, latitude, longitude, cidade, estado, tipo,
                foto_capa, fotos, tags, avg_nota, total_avaliacoes, criado_por, criado_em
                ${distanciaSelect}
         FROM pontos_de_pesca ${where}
         ORDER BY ${orderBy}
         LIMIT $${i++} OFFSET $${i++}`,
        [...values, porPagina, offset]
      ),
      pool.query(`SELECT COUNT(*) FROM pontos_de_pesca ${where}`, values.slice(0, values.length - (distanciaSelect ? 3 : 0) + (distanciaSelect ? 3 : 0))),
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
    const result = await pool.query('SELECT * FROM pontos_de_pesca WHERE id = $1', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'PONTO_NAO_ENCONTRADO', message: 'Ponto de pesca não encontrado.' });
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
    const existe = await pool.query('SELECT criado_por FROM pontos_de_pesca WHERE id = $1', [id]);
    if (existe.rows.length === 0) {
      return res.status(404).json({ error: 'PONTO_NAO_ENCONTRADO', message: 'Ponto de pesca não encontrado.' });
    }
    if (existe.rows[0].criado_por !== usuarioId) {
      return res.status(403).json({ error: 'FORBIDDEN', message: 'Você não tem permissão para editar este ponto.' });
    }

    const { nome, descricao, latitude, longitude, cidade, estado, tipo, fotoCapa, fotos, tags } = req.body;
    const fields = [];
    const values = [];
    let i = 1;

    if (nome !== undefined) { fields.push(`nome = $${i++}`); values.push(nome); }
    if (descricao !== undefined) { fields.push(`descricao = $${i++}`); values.push(descricao); }
    if (latitude !== undefined) { fields.push(`latitude = $${i++}`); values.push(latitude); }
    if (longitude !== undefined) { fields.push(`longitude = $${i++}`); values.push(longitude); }
    if (cidade !== undefined) { fields.push(`cidade = $${i++}`); values.push(cidade); }
    if (estado !== undefined) { fields.push(`estado = $${i++}`); values.push(estado.toUpperCase()); }
    if (tipo !== undefined) { fields.push(`tipo = $${i++}`); values.push(tipo); }
    if (fotoCapa !== undefined) { fields.push(`foto_capa = $${i++}`); values.push(fotoCapa); }
    if (fotos !== undefined) { fields.push(`fotos = $${i++}`); values.push(fotos); }
    if (tags !== undefined) { fields.push(`tags = $${i++}`); values.push(tags); }

    if (fields.length === 0) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Nenhum campo para atualizar.' });
    }

    fields.push(`atualizado_em = NOW()`);
    values.push(id);

    const result = await pool.query(
      `UPDATE pontos_de_pesca SET ${fields.join(', ')} WHERE id = $${i} RETURNING *`,
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
    const existe = await pool.query('SELECT criado_por FROM pontos_de_pesca WHERE id = $1', [id]);
    if (existe.rows.length === 0) {
      return res.status(404).json({ error: 'PONTO_NAO_ENCONTRADO', message: 'Ponto de pesca não encontrado.' });
    }
    if (existe.rows[0].criado_por !== usuarioId) {
      return res.status(403).json({ error: 'FORBIDDEN', message: 'Você não tem permissão para deletar este ponto.' });
    }

    await pool.query('DELETE FROM pontos_de_pesca WHERE id = $1', [id]);
    return res.status(204).send();
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

function _format(p) {
  return {
    id: p.id,
    nome: p.nome,
    descricao: p.descricao,
    latitude: parseFloat(p.latitude),
    longitude: parseFloat(p.longitude),
    cidade: p.cidade,
    estado: p.estado,
    tipo: p.tipo,
    fotoCapa: p.foto_capa,
    fotos: p.fotos ?? [],
    tags: p.tags ?? [],
    avgNota: parseFloat(p.avg_nota) || 0,
    totalAvaliacoes: p.total_avaliacoes,
    distanciaKm: p.distancia_km ? parseFloat(p.distancia_km) : undefined,
    criadoPor: p.criado_por,
    criadoEm: p.criado_em,
  };
}

module.exports = { criar, listar, buscarPorId, atualizar, deletar };