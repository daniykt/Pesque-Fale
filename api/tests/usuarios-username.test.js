process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const token = gerarToken('user-1');

function patchMe(body) {
  return request(app)
    .patch('/v1/usuarios/me')
    .set('Authorization', `Bearer ${token}`)
    .send(body);
}

function consultasUsername() {
  return pool.query.mock.calls.filter(([sql]) => sql.includes('WHERE username = $1 AND id != $2'));
}

function chamadaUpdate() {
  return pool.query.mock.calls.find(([sql]) => sql.includes('UPDATE usuarios SET'));
}

describe('PATCH /v1/usuarios/me — username', () => {
  let consoleErrorSpy;

  beforeEach(() => {
    pool.query.mockReset();
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    consoleErrorSpy.mockRestore();
  });

  it('username em uso por outro usuário responde 409 USERNAME_JA_CADASTRADO', async () => {
    pool.query.mockResolvedValueOnce({ rows: [{ id: 'user-2' }] }); // checagem de unicidade

    const res = await patchMe({ username: 'ocupado' });

    expect(res.status).toBe(409);
    expect(res.body).toEqual({
      error: 'USERNAME_JA_CADASTRADO',
      message: 'Este username já está em uso.',
    });
    expect(consultasUsername()).toHaveLength(1);
    expect(consultasUsername()[0][1]).toEqual(['ocupado', 'user-1']);
    expect(chamadaUpdate()).toBeUndefined();
  });

  it('username com formato inválido responde 400 VALIDATION_ERROR sem consultar o banco', async () => {
    const res = await patchMe({ username: 'a!' });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('VALIDATION_ERROR');
    expect(res.body.details).toEqual([
      { campo: 'username', mensagem: 'Username deve ter 3-20 caracteres: letras, números, _ ou .' },
    ]);
    expect(pool.query).not.toHaveBeenCalled();
  });

  it('falha do banco na checagem do username responde 500 INTERNAL_ERROR', async () => {
    pool.query.mockRejectedValueOnce(new Error('conexão perdida'));

    const res = await patchMe({ username: 'livre_123' });

    expect(res.status).toBe(500);
    expect(res.body.error).toBe('INTERNAL_ERROR');
    expect(consoleErrorSpy).toHaveBeenCalled();
    expect(chamadaUpdate()).toBeUndefined();
  });

  it('username livre segue para o UPDATE e responde 200', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [] }) // checagem de unicidade: ninguém usa
      .mockResolvedValueOnce({
        rows: [{
          id: 'user-1',
          nome: 'Fulano',
          email: 'fulano@teste.com',
          username: 'livre_123',
          foto_perfil: null,
          banner: null,
          bio: '',
          localizacao: '',
          onboarding_concluido: true,
          criado_em: '2026-01-01T00:00:00.000Z',
        }],
      })
      .mockResolvedValueOnce({ rows: [{ count: '0' }] })
      .mockResolvedValueOnce({ rows: [{ count: '0' }] });

    const res = await patchMe({ username: 'livre_123' });

    expect(res.status).toBe(200);
    expect(res.body.data.username).toBe('livre_123');
    const [sql, valores] = chamadaUpdate();
    expect(sql).toContain('username =');
    expect(valores).toEqual(['livre_123', 'user-1']);
  });
});
