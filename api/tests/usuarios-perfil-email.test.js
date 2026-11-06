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
    // Sem login, a query devolve sou_seguidor e me_segue NULL.
    pool.query.mockResolvedValueOnce({
      rows: [{ ...linhaUsuario(), sou_seguidor: null, me_segue: null }],
    });

    const res = await request(app).get('/v1/usuarios/user-1');

    expect(res.status).toBe(200);
    expect(res.body.data).not.toHaveProperty('email');
    expect(res.body.data.username).toBe('fulano');
    expect(res.body.data.souSeguidor).toBeNull();
    expect(res.body.data.meSegue).toBeNull();
    // Quem vê ($2) é null quando não há token.
    expect(pool.query.mock.calls[0][1]).toEqual(['user-1', null]);
  });

  it('perfil público com token de outro usuário não expõe email e resolve o follow em 1 ida ao banco', async () => {
    // souSeguidor e meSegue vêm na própria query do perfil.
    pool.query.mockResolvedValueOnce({
      rows: [{ ...linhaUsuario(), sou_seguidor: true, me_segue: false }],
    });

    const res = await request(app)
      .get('/v1/usuarios/user-1')
      .set('Authorization', `Bearer ${gerarToken('user-2')}`);

    expect(res.status).toBe(200);
    expect(res.body.data).not.toHaveProperty('email');
    expect(res.body.data.souSeguidor).toBe(true);
    expect(res.body.data.meSegue).toBe(false);
    expect(pool.query.mock.calls.length).toBe(1);
    const [sql, params] = pool.query.mock.calls[0];
    expect(sql).toContain('AS sou_seguidor');
    expect(sql).toContain('AS me_segue');
    expect(params).toEqual(['user-1', 'user-2']);
  });

  it('/me com token inclui o email do próprio usuário', async () => {
    // Mesmo id do token: a query devolve sou_seguidor e me_segue NULL.
    pool.query.mockResolvedValueOnce({
      rows: [{ ...linhaUsuario(), sou_seguidor: null, me_segue: null }],
    });

    const res = await request(app)
      .get('/v1/usuarios/me')
      .set('Authorization', `Bearer ${gerarToken('user-1')}`);

    expect(res.status).toBe(200);
    expect(res.body.data.email).toBe(EMAIL);
    expect(res.body.data.id).toBe('user-1');
    expect(res.body.data.souSeguidor).toBeNull();
    expect(res.body.data.meSegue).toBeNull();
    expect(pool.query).toHaveBeenCalledTimes(1);
    expect(pool.query.mock.calls[0][1]).toEqual(['user-1', 'user-1']);
  });

  it('perfil de id inexistente responde 404 USUARIO_NAO_ENCONTRADO', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app).get('/v1/usuarios/nao-existe');

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('USUARIO_NAO_ENCONTRADO');
  });
});
