const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../../config/database');

async function cadastro(req, res) {
  const { nome, email, senha, confirmarSenha } = req.body;

  if (!nome || !email || !senha || !confirmarSenha) {
    return res.status(400).json({
      error: 'VALIDATION_ERROR',
      message: 'Verifique os campos e tente novamente.',
      details: [{ campo: 'geral', mensagem: 'Todos os campos são obrigatórios.' }],
    });
  }

  if (nome.length < 2) {
    return res.status(400).json({
      error: 'VALIDATION_ERROR',
      message: 'Verifique os campos e tente novamente.',
      details: [{ campo: 'nome', mensagem: 'O nome deve ter pelo menos 2 caracteres.' }],
    });
  }

  if (senha.length < 6) {
    return res.status(400).json({
      error: 'VALIDATION_ERROR',
      message: 'Verifique os campos e tente novamente.',
      details: [{ campo: 'senha', mensagem: 'A senha deve ter pelo menos 6 caracteres.' }],
    });
  }

  if (senha !== confirmarSenha) {
    return res.status(400).json({
      error: 'VALIDATION_ERROR',
      message: 'Verifique os campos e tente novamente.',
      details: [{ campo: 'confirmarSenha', mensagem: 'As senhas não conferem.' }],
    });
  }

  try {
    const emailExiste = await pool.query('SELECT id FROM usuarios WHERE email = $1', [email]);
    if (emailExiste.rows.length > 0) {
      return res.status(409).json({
        error: 'EMAIL_JA_CADASTRADO',
        message: 'Este email já está em uso.',
      });
    }

    const senha_hash = await bcrypt.hash(senha, 12);

    const result = await pool.query(
      `INSERT INTO usuarios (nome, email, senha_hash, onboarding_concluido)
       VALUES ($1, $2, $3, false)
       RETURNING id, nome, email, username, foto_perfil, banner, bio, localizacao, onboarding_concluido, criado_em`,
      [nome, email, senha_hash]
    );

    const usuario = result.rows[0];

    const access_token = jwt.sign(
      { id: usuario.id, email: usuario.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    return res.status(201).json({
      data: {
        access_token,
        usuario: {
          id: usuario.id,
          nome: usuario.nome,
          email: usuario.email,
          username: usuario.username,
          fotoPerfil: usuario.foto_perfil,
          banner: usuario.banner,
          bio: usuario.bio,
          localizacao: usuario.localizacao,
          onboardingConcluido: usuario.onboarding_concluido,
          seguidores: 0,
          seguindo: 0,
          criadoEm: usuario.criado_em,
        },
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

async function login(req, res) {
  const { email, senha } = req.body;

  if (!email || !senha) {
    return res.status(400).json({
      error: 'VALIDATION_ERROR',
      message: 'Verifique os campos e tente novamente.',
      details: [{ campo: 'geral', mensagem: 'Email e senha são obrigatórios.' }],
    });
  }

  try {
    const result = await pool.query(
      `SELECT id, nome, email, username, senha_hash, foto_perfil, banner, bio, localizacao, onboarding_concluido, criado_em
       FROM usuarios WHERE email = $1`,
      [email]
    );

    const usuario = result.rows[0];

    if (!usuario) {
      return res.status(401).json({
        error: 'CREDENCIAIS_INVALIDAS',
        message: 'Email ou senha incorretos.',
      });
    }

    const senhaValida = await bcrypt.compare(senha, usuario.senha_hash);
    if (!senhaValida) {
      return res.status(401).json({
        error: 'CREDENCIAIS_INVALIDAS',
        message: 'Email ou senha incorretos.',
      });
    }

    const access_token = jwt.sign(
      { id: usuario.id, email: usuario.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    return res.status(200).json({
      data: {
        access_token,
        usuario: {
          id: usuario.id,
          nome: usuario.nome,
          email: usuario.email,
          username: usuario.username,
          fotoPerfil: usuario.foto_perfil,
          banner: usuario.banner,
          bio: usuario.bio,
          localizacao: usuario.localizacao,
          onboardingConcluido: usuario.onboarding_concluido,
          seguidores: 0,
          seguindo: 0,
          criadoEm: usuario.criado_em,
        },
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

module.exports = { cadastro, login };