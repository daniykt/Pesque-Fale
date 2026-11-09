process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const usuarioMock = {
  id: 'user-1',
  nome: 'Fulano',
  email: 'fulano@teste.com',
  username: 'fulano',
  foto_perfil: null,
  banner: null,
  bio: '',
  localizacao: '',
  onboarding_concluido: false,
  criado_em: '2026-01-01T00:00:00.000Z',
};

describe('POST /v1/auth/cadastro', () => {
  beforeEach(() => pool.query.mockReset());

  it('201 com campos válidos', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: [usuarioMock] });

    const res = await request(app).post('/v1/auth/cadastro').send({
      nome: 'Fulano',
      email: 'fulano@teste.com',
      senha: '123456',
      confirmarSenha: '123456',
    });

    expect(res.status).toBe(201);
    expect(res.body.data).toHaveProperty('access_token');
    expect(res.body.data.usuario.email).toBe('fulano@teste.com');
  });

  it('400 quando nome tem menos de 2 caracteres', async () => {
    const res = await request(app).post('/v1/auth/cadastro').send({
      nome: 'F',
      email: 'fulano@teste.com',
      senha: '123456',
      confirmarSenha: '123456',
    });
    expect(res.status).toBe(400);
    expect(res.body.error).toBe('VALIDATION_ERROR');
  });

  it('400 quando senha tem menos de 6 caracteres', async () => {
    const res = await request(app).post('/v1/auth/cadastro').send({
      nome: 'Fulano',
      email: 'fulano@teste.com',
      senha: '123',
      confirmarSenha: '123',
    });
    expect(res.status).toBe(400);
    expect(res.body.details[0].campo).toBe('senha');
  });

  it('400 quando senhas não conferem', async () => {
    const res = await request(app).post('/v1/auth/cadastro').send({
      nome: 'Fulano',
      email: 'fulano@teste.com',
      senha: '123456',
      confirmarSenha: '654321',
    });
    expect(res.status).toBe(400);
    expect(res.body.details[0].campo).toBe('confirmarSenha');
  });

  it('409 quando email já existe', async () => {
    pool.query.mockResolvedValueOnce({ rows: [{ id: 'user-x' }] });

    const res = await request(app).post('/v1/auth/cadastro').send({
      nome: 'Fulano',
      email: 'fulano@teste.com',
      senha: '123456',
      confirmarSenha: '123456',
    });
    expect(res.status).toBe(409);
    expect(res.body.error).toBe('EMAIL_JA_CADASTRADO');
  });
});

describe('POST /v1/auth/login', () => {
  beforeEach(() => pool.query.mockReset());

  it('200 com credenciais válidas', async () => {
    const bcrypt = require('bcryptjs');
    const hash = await bcrypt.hash('123456', 1);
    pool.query.mockResolvedValueOnce({
      rows: [{ ...usuarioMock, senha_hash: hash }],
    });

    const res = await request(app).post('/v1/auth/login').send({
      email: 'fulano@teste.com',
      senha: '123456',
    });
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveProperty('access_token');
  });

  it('401 com senha errada', async () => {
    const bcrypt = require('bcryptjs');
    const hash = await bcrypt.hash('outrasenha', 1);
    pool.query.mockResolvedValueOnce({
      rows: [{ ...usuarioMock, senha_hash: hash }],
    });

    const res = await request(app).post('/v1/auth/login').send({
      email: 'fulano@teste.com',
      senha: '123456',
    });
    expect(res.status).toBe(401);
    expect(res.body.error).toBe('CREDENCIAIS_INVALIDAS');
  });

  it('401 quando usuário não existe', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app).post('/v1/auth/login').send({
      email: 'naoexiste@teste.com',
      senha: '123456',
    });
    expect(res.status).toBe(401);
    expect(res.body.error).toBe('CREDENCIAIS_INVALIDAS');
  });
});

describe('Middleware JWT', () => {
  it('401 sem token em rota protegida', async () => {
    const res = await request(app).get('/v1/usuarios/me');
    expect(res.status).toBe(401);
    expect(res.body.error).toBe('TOKEN_INVALIDO');
  });

  it('401 com token inválido', async () => {
    const res = await request(app)
      .get('/v1/usuarios/me')
      .set('Authorization', 'Bearer token_invalido');
    expect(res.status).toBe(401);
    expect(res.body.error).toBe('TOKEN_INVALIDO');
  });

  it('200 com token válido', async () => {
    pool.query.mockReset();
    pool.query.mockResolvedValue({
      rows: [{ ...usuarioMock, seguidores: '0', seguindo: '0' }],
    });
    const token = gerarToken('user-1');
    const res = await request(app)
      .get('/v1/usuarios/me')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
  });
});