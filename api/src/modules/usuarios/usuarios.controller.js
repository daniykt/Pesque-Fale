const pool = require('../../config/database');

const USERNAME_REGEX = /^[a-zA-Z0-9_.]{3,20}$/;

async function getPerfil(req, res) {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `SELECT u.id, u.nome, u.email, u.username, u.foto_perfil, u.banner, u.bio, u.localizacao, u.onboarding_concluido, u.criado_em,
        (SELECT COUNT(*) FROM usuario_seguidores WHERE seguido_id = u.id) AS seguidores,
        (SELECT COUNT(*) FROM usuario_seguidores WHERE seguidor_id = u.id) AS seguindo
       FROM usuarios u WHERE u.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'USUARIO_NAO_ENCONTRADO', message: 'Usuário não encontrado.' });
    }

    const u = result.rows[0];
    return res.json({
      data: {
        id: u.id,
        nome: u.nome,
        email: u.email,
        username: u.username,
        fotoPerfil: u.foto_perfil,
        banner: u.banner,
        bio: u.bio,
        localizacao: u.localizacao,
        onboardingConcluido: u.onboarding_concluido,
        seguidores: parseInt(u.seguidores),
        seguindo: parseInt(u.seguindo),
        criadoEm: u.criado_em,
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function getMe(req, res) {
  req.params.id = req.usuario.id;
  return getPerfil(req, res);
}

async function updateMe(req, res) {
  const { nome, bio, localizacao, username, fotoPerfil, banner } = req.body;
  const usuarioId = req.usuario.id;

  const details = [];

  if (nome !== undefined && nome.length < 2) {
    details.push({ campo: 'nome', mensagem: 'O nome deve ter pelo menos 2 caracteres.' });
  }

  if (username !== undefined) {
    if (!USERNAME_REGEX.test(username)) {
      details.push({ campo: 'username', mensagem: 'Username deve ter 3-20 caracteres: letras, números, _ ou .' });
    } else {
      const existe = await pool.query(
        'SELECT id FROM usuarios WHERE username = $1 AND id != $2',
        [username, usuarioId]
      );
      if (existe.rows.length > 0) {
        details.push({ campo: 'username', mensagem: 'Este username já está em uso.' });
      }
    }
  }

  if (details.length > 0) {
    return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Verifique os campos e tente novamente.', details });
  }

  try {
    const fields = [];
    const values = [];
    let i = 1;

    if (nome !== undefined) { fields.push(`nome = $${i++}`); values.push(nome); }
    if (bio !== undefined) { fields.push(`bio = $${i++}`); values.push(bio); }
    if (localizacao !== undefined) { fields.push(`localizacao = $${i++}`); values.push(localizacao); }
    if (username !== undefined) { fields.push(`username = $${i++}`); values.push(username); }
    if (fotoPerfil !== undefined) { fields.push(`foto_perfil = $${i++}`); values.push(fotoPerfil); }
    if (banner !== undefined) { fields.push(`banner = $${i++}`); values.push(banner); }

    if (fields.length === 0) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Nenhum campo para atualizar.' });
    }

    fields.push(`atualizado_em = NOW()`);
    values.push(usuarioId);

    const result = await pool.query(
      `UPDATE usuarios SET ${fields.join(', ')} WHERE id = $${i}
       RETURNING id, nome, email, username, foto_perfil, banner, bio, localizacao, onboarding_concluido, criado_em`,
      values
    );

    const u = result.rows[0];

    const seguidores = await pool.query('SELECT COUNT(*) FROM usuario_seguidores WHERE seguido_id = $1', [usuarioId]);
    const seguindo = await pool.query('SELECT COUNT(*) FROM usuario_seguidores WHERE seguidor_id = $1', [usuarioId]);

    return res.json({
      data: {
        id: u.id,
        nome: u.nome,
        email: u.email,
        username: u.username,
        fotoPerfil: u.foto_perfil,
        banner: u.banner,
        bio: u.bio,
        localizacao: u.localizacao,
        onboardingConcluido: u.onboarding_concluido,
        seguidores: parseInt(seguidores.rows[0].count),
        seguindo: parseInt(seguindo.rows[0].count),
        criadoEm: u.criado_em,
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function checkUsername(req, res) {
  const { username } = req.params;

  if (!USERNAME_REGEX.test(username)) {
    return res.json({ data: { disponivel: false } });
  }

  try {
    const result = await pool.query('SELECT id FROM usuarios WHERE username = $1', [username]);
    return res.json({ data: { disponivel: result.rows.length === 0 } });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function seguir(req, res) {
  const seguidorId = req.usuario.id;
  const seguidoId = req.params.id;

  if (seguidorId === seguidoId) {
    return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Você não pode seguir a si mesmo.' });
  }

  try {
    const usuarioExiste = await pool.query('SELECT id FROM usuarios WHERE id = $1', [seguidoId]);
    if (usuarioExiste.rows.length === 0) {
      return res.status(404).json({ error: 'USUARIO_NAO_ENCONTRADO', message: 'Usuário não encontrado.' });
    }

    await pool.query(
      'INSERT INTO usuario_seguidores (seguidor_id, seguido_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [seguidorId, seguidoId]
    );

    return res.status(201).json({ data: { message: 'Usuário seguido com sucesso.' } });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function deixarDeSeguir(req, res) {
  const seguidorId = req.usuario.id;
  const seguidoId = req.params.id;

  try {
    await pool.query(
      'DELETE FROM usuario_seguidores WHERE seguidor_id = $1 AND seguido_id = $2',
      [seguidorId, seguidoId]
    );

    return res.status(204).send();
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

module.exports = { getPerfil, getMe, updateMe, checkUsername, seguir, deixarDeSeguir };