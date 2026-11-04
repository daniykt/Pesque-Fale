process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const EMAIL = 'fulano@teste.com';

function linhaUsuario() {
  return {
    id: 'user-1',
    nome: 'Fulano',
    email: EMAIL,
    username: 'fulano',
    foto_perfil: null,
    banner: null,
    bio: '',
    localizacao: '',
    onboarding_concluido: true,
    criado_em: '2026-01-01T00:00:00.000Z',
    seguidores: '3',
    seguindo: '5',
  };
}

describe('GET /v1/usuarios/:id e /v1/usuarios/me — exposição de email', () => {
  beforeEach(() => {
    pool.query.mockReset();
  });

  it('perfil público sem token não expõe email', async () => {
    pool.query.mockResolvedValueOnce({ rows: [linhaUsuario()] });

    const res = await request(app).get('/v1/usuarios/user-1');

    expect(res.status).toBe(200);
    expect(res.body.data).not.toHaveProperty('email');
    expect(res.body.data.username).toBe('fulano');
    expect(res.body.data.souSeguidor).toBeNull();
    expect(res.body.data.meSegue).toBeNull();
  });

  it('perfil público com token de outro usuário não expõe email', async () => {
    // getPerfil: 1 SELECT do perfil + 2 queries de follow em Promise.all
    // (souSeguidor e meSegue, nessa ordem).
    pool.query
      .mockResolvedValueOnce({ rows: [linhaUsuario()] })
      .mockResolvedValueOnce({ rows: [{ '?column?': 1 }] })
      .mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .get('/v1/usuarios/user-1')
      .set('Authorization', `Bearer ${gerarToken('user-2')}`);

    expect(res.status).toBe(200);
    expect(res.body.data).not.toHaveProperty('email');
    expect(res.body.data.souSeguidor).toBe(true);
    expect(res.body.data.meSegue).toBe(false);
    expect(pool.query).toHaveBeenCalledTimes(3);
  });

  it('/me com token inclui o email do próprio usuário', async () => {
    // Mesmo id do token: não roda as queries de follow.
    pool.query.mockResolvedValueOnce({ rows: [linhaUsuario()] });

    const res = await request(app)
      .get('/v1/usuarios/me')
      .set('Authorization', `Bearer ${gerarToken('user-1')}`);

    expect(res.status).toBe(200);
    expect(res.body.data.email).toBe(EMAIL);
    expect(res.body.data.id).toBe('user-1');
    expect(pool.query).toHaveBeenCalledTimes(1);
  });

  it('perfil de id inexistente responde 404 USUARIO_NAO_ENCONTRADO', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app).get('/v1/usuarios/nao-existe');

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('USUARIO_NAO_ENCONTRADO');
  });
});
