jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const CAMPOS_SENSIVEIS = ['senha_hash', 'firebase_uid'];

function verificarCamposSensiveis(obj, caminho = '') {
  for (const campo of CAMPOS_SENSIVEIS) {
    expect(
      Object.prototype.hasOwnProperty.call(obj, campo),
    ).toBe(false);
  }
  for (const [chave, valor] of Object.entries(obj)) {
    if (valor && typeof valor === 'object' && !Array.isArray(valor)) {
      verificarCamposSensiveis(valor, `${caminho}.${chave}`);
    }
  }
}

const usuarioMock = {
  id: 'user-1',
  nome: 'Fulano',
  email: 'fulano@teste.com',
  username: 'fulano',
  senha_hash: '$2b$12$hash_secreto_que_nao_deve_aparecer',
  firebase_uid: 'firebase_uid_secreto',
  foto_perfil: null,
  banner: null,
  bio: '',
  localizacao: '',
  onboarding_concluido: false,
  criado_em: '2026-01-01T00:00:00.000Z',
};

describe('Segurança — serializer não expõe campos sensíveis', () => {
  beforeEach(() => {
    pool.query.mockReset();
  });

  it('POST /auth/cadastro não expõe senha_hash nem firebase_uid', async () => {
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
    verificarCamposSensiveis(res.body);
  });

  it('POST /auth/login não expõe senha_hash nem firebase_uid', async () => {
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
    verificarCamposSensiveis(res.body);
  });

  it('GET /usuarios/me não expõe senha_hash nem firebase_uid', async () => {
    pool.query.mockResolvedValue({
      rows: [{ ...usuarioMock, seguidores: '0', seguindo: '0' }],
    });

    const token = gerarToken('user-1');
    const res = await request(app)
      .get('/v1/usuarios/me')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    verificarCamposSensiveis(res.body);
  });

  it('GET /usuarios/:id não expõe senha_hash nem firebase_uid', async () => {
    pool.query.mockResolvedValue({
      rows: [{ ...usuarioMock, seguidores: '0', seguindo: '0' }],
    });

    const res = await request(app).get('/v1/usuarios/user-1');

    expect(res.status).toBe(200);
    verificarCamposSensiveis(res.body);
  });

it('PATCH /usuarios/me não expõe senha_hash nem firebase_uid', async () => {
  pool.query
    .mockResolvedValueOnce({ rows: [usuarioMock] })
    .mockResolvedValueOnce({ rows: [{ count: '0' }] })
    .mockResolvedValueOnce({ rows: [{ count: '0' }] });

  const token = gerarToken('user-1');
  const res = await request(app)
    .patch('/v1/usuarios/me')
    .set('Authorization', `Bearer ${token}`)
    .send({ bio: 'Nova bio' });

  expect(res.status).toBe(200);
  verificarCamposSensiveis(res.body);
});
});