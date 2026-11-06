process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const token = gerarToken('user-1');

// O que o Postgres devolve quando o id da URL não é um UUID (ex.: /usuarios/abc).
function erroUuidInvalido() {
  return Object.assign(new Error('invalid input syntax for type uuid: "abc"'), { code: '22P02' });
}

const rotas = [
  ['GET /usuarios/:id', () => request(app).get('/v1/usuarios/abc')],
  ['GET /usuarios/:id/seguidores', () => request(app).get('/v1/usuarios/abc/seguidores')],
  ['GET /usuarios/:id/seguindo', () => request(app).get('/v1/usuarios/abc/seguindo')],
  [
    'POST /usuarios/:id/seguir',
    () => request(app).post('/v1/usuarios/abc/seguir').set('Authorization', `Bearer ${token}`),
  ],
  [
    'DELETE /usuarios/:id/seguir',
    () => request(app).delete('/v1/usuarios/abc/seguir').set('Authorization', `Bearer ${token}`),
  ],
];

describe('rotas de usuário — id que não é UUID', () => {
  let consoleErrorSpy;

  beforeEach(() => {
    pool.query.mockReset();
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    consoleErrorSpy.mockRestore();
  });

  it.each(rotas)('%s responde 404 USUARIO_NAO_ENCONTRADO', async (_nome, chamar) => {
    pool.query.mockRejectedValueOnce(erroUuidInvalido());

    const res = await chamar();

    expect(res.status).toBe(404);
    expect(res.body).toEqual({
      error: 'USUARIO_NAO_ENCONTRADO',
      message: 'Usuário não encontrado.',
    });
    expect(consoleErrorSpy).not.toHaveBeenCalled();
  });

  it('erro do banco sem code continua 500 INTERNAL_ERROR', async () => {
    pool.query.mockRejectedValueOnce(new Error('conexão perdida'));

    const res = await request(app).get('/v1/usuarios/abc');

    expect(res.status).toBe(500);
    expect(res.body.error).toBe('INTERNAL_ERROR');
    expect(consoleErrorSpy).toHaveBeenCalled();
  });
});
