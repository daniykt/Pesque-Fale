const pool = require('../../config/database');

const COLUNAS_ORGANIZADOR =
  'u.nome AS organizador_nome, u.username AS organizador_username, u.foto_perfil AS organizador_foto';

async function criar(req, res) {
  const organizadorId = req.usuario.id;
  const { titulo, descricao, pontoId, imagemUrl, localTexto } = req.body;

  const { erros, datas } = _validar(req.body, { exigirObrigatorios: true });
  if (erros.length > 0) {
    return _erroValidacao(res, erros);
  }

  try {
    const result = await pool.query(
      `WITH novo AS (
         INSERT INTO eventos (titulo, descricao, ponto_id, organizador_id, data_inicio, data_fim, imagem_url, local_texto)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *
       )
       SELECT novo.*, ${COLUNAS_ORGANIZADOR}
       FROM novo
       JOIN usuarios u ON u.id = novo.organizador_id`,
      [titulo, descricao ?? null, pontoId ?? null, organizadorId,
       datas.dataInicio, datas.dataFim ?? null, imagemUrl ?? null, localTexto ?? null]
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
    conditions.push(`COALESCE(data_fim, data_inicio) >= NOW()`);
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
         ORDER BY e.data_inicio ${futuros === 'true' ? 'ASC' : 'DESC'}
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
    const existe = await pool.query('SELECT organizador_id, data_inicio, data_fim FROM eventos WHERE id = $1', [id]);
    if (existe.rows.length === 0) {
      return res.status(404).json({ error: 'EVENTO_NAO_ENCONTRADO', message: 'Evento não encontrado.' });
    }
    if (existe.rows[0].organizador_id !== usuarioId) {
      return res.status(403).json({ error: 'FORBIDDEN', message: 'Você não tem permissão para editar este evento.' });
    }

    const { erros, datas } = _validar(req.body, { salvo: existe.rows[0] });
    if (erros.length > 0) {
      return _erroValidacao(res, erros);
    }

    const { titulo, descricao, pontoId, imagemUrl, localTexto } = req.body;
    const fields = [];
    const values = [];
    let i = 1;

    if (titulo !== undefined) { fields.push(`titulo = $${i++}`); values.push(titulo); }
    if (descricao !== undefined) { fields.push(`descricao = $${i++}`); values.push(descricao); }
    if (pontoId !== undefined) { fields.push(`ponto_id = $${i++}`); values.push(pontoId); }
    if (datas.dataInicio !== undefined) { fields.push(`data_inicio = $${i++}`); values.push(datas.dataInicio); }
    if (datas.dataFim !== undefined) { fields.push(`data_fim = $${i++}`); values.push(datas.dataFim); }
    if (imagemUrl !== undefined) { fields.push(`imagem_url = $${i++}`); values.push(imagemUrl); }
    if (localTexto !== undefined) { fields.push(`local_texto = $${i++}`); values.push(localTexto); }

    if (fields.length === 0) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Nenhum campo para atualizar.' });
    }

    fields.push(`atualizado_em = NOW()`);
    values.push(id);

    const result = await pool.query(
      `WITH atualizado AS (
         UPDATE eventos SET ${fields.join(', ')} WHERE id = $${i} RETURNING *
       )
       SELECT atualizado.*, ${COLUNAS_ORGANIZADOR}
       FROM atualizado
       JOIN usuarios u ON u.id = atualizado.organizador_id`,
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

const DATA_ISO = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,6}))?)?(Z|[+-]\d{2}:\d{2})?$/;

function _lerData(valor) {
  if (typeof valor !== 'string') return { erro: 'invalida' };
  const partes = valor.match(DATA_ISO);
  if (!partes) return { erro: 'invalida' };
  const [ano, mes, dia, hora, minuto, segundo] = partes.slice(1, 7).map(v => Number(v ?? 0));
  const milissegundos = Number((partes[7] ?? '').padEnd(3, '0').slice(0, 3));
  const fuso = partes[8];
  const relogio = new Date(Date.UTC(ano, mes - 1, dia, hora, minuto, segundo, milissegundos));
  const confere =
    relogio.getUTCFullYear() === ano &&
    relogio.getUTCMonth() === mes - 1 &&
    relogio.getUTCDate() === dia &&
    relogio.getUTCHours() === hora &&
    relogio.getUTCMinutes() === minuto &&
    relogio.getUTCSeconds() === segundo;
  if (!confere) return { erro: 'invalida' };
  if (!fuso) return { erro: 'semFuso' };
  if (fuso === 'Z') return { data: relogio };
  const [horasFuso, minutosFuso] = fuso.slice(1).split(':').map(Number);
  if (horasFuso > 14 || minutosFuso > 59) return { erro: 'invalida' };
  const sinal = fuso[0] === '-' ? -1 : 1;
  const deslocamentoMs = sinal * (horasFuso * 60 + minutosFuso) * 60000;
  return { data: new Date(relogio.getTime() - deslocamentoMs) };
}

function _mensagemData(rotulo, erro) {
  if (erro === 'semFuso') {
    return `Data de ${rotulo} inválida. Informe o fuso (ex.: 2026-11-20T11:00:00Z).`;
  }
  return `Data de ${rotulo} inválida. Use o formato ISO-8601 com fuso (ex.: 2026-11-20T11:00:00Z).`;
}

function _validar(body, { exigirObrigatorios = false, salvo = null } = {}) {
  const { titulo, localTexto, dataInicio, dataFim } = body;
  const erros = [];
  const datas = {};

  if (exigirObrigatorios || titulo !== undefined) {
    if (typeof titulo !== 'string' || titulo.trim().length < 2 || titulo.length > 200) {
      erros.push({ campo: 'titulo', mensagem: 'Título deve ter entre 2 e 200 caracteres.' });
    }
  }

  if (localTexto !== undefined && localTexto !== null) {
    if (typeof localTexto !== 'string' || localTexto.length > 150) {
      erros.push({ campo: 'localTexto', mensagem: 'Local deve ter no máximo 150 caracteres.' });
    }
  }

  let inicio = salvo ? salvo.data_inicio : null;
  if (exigirObrigatorios || dataInicio !== undefined) {
    if (dataInicio === undefined || dataInicio === null || dataInicio === '') {
      erros.push({ campo: 'dataInicio', mensagem: 'Data de início é obrigatória.' });
      inicio = null;
    } else {
      const lida = _lerData(dataInicio);
      inicio = lida.data ?? null;
      if (lida.erro) {
        erros.push({ campo: 'dataInicio', mensagem: _mensagemData('início', lida.erro) });
      } else {
        datas.dataInicio = inicio.toISOString();
      }
    }
  }

  let fim = salvo ? salvo.data_fim : null;
  if (dataFim !== undefined) {
    if (dataFim === null) {
      fim = null;
      datas.dataFim = null;
    } else {
      const lida = _lerData(dataFim);
      fim = lida.data ?? null;
      if (lida.erro) {
        erros.push({ campo: 'dataFim', mensagem: _mensagemData('fim', lida.erro) });
      } else {
        datas.dataFim = fim.toISOString();
      }
    }
  }

  if (inicio && fim && fim < inicio) {
    erros.push({ campo: 'dataFim', mensagem: 'A data de fim deve ser igual ou posterior à data de início.' });
  }

  return { erros, datas };
}

function _erroValidacao(res, erros) {
  return res.status(400).json({
    error: 'VALIDATION_ERROR',
    message: 'Verifique os campos.',
    details: erros,
  });
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