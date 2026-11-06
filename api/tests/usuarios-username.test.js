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

function chamadaUpdate() {
  return pool.query.mock.calls.find(([sql]) => sql.includes('UPDATE usuarios SET'));
}

// O que o Postgres devolve quando o UPDATE bate numa constraint UNIQUE.
function erroUnique(constraint) {
  return Object.assign(new Error('duplicate key value violates unique constraint'), {
    code: '23505',
    constraint,
  });
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
    // A unicidade é garantida pela constraint usuarios_username_key: o UPDATE falha com 23505.
    pool.query.mockRejectedValueOnce(erroUnique('usuarios_username_key'));

    const res = await patchMe({ username: 'ocupado' });

    expect(res.status).toBe(409);
    expect(res.body).toEqual({
      error: 'USERNAME_JA_CADASTRADO',
      message: 'Este username já está em uso.',
    });
    expect(pool.query.mock.calls.length).toBe(1);
    const [sql, valores] = chamadaUpdate();
    expect(sql).toContain('username =');
    expect(valores).toEqual(['ocupado', 'user-1']);
    expect(consoleErrorSpy).not.toHaveBeenCalled();
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

  it('falha do banco ao salvar o username responde 500 INTERNAL_ERROR', async () => {
    pool.query.mockRejectedValueOnce(new Error('conexão perdida'));

    const res = await patchMe({ username: 'livre_123' });

    expect(res.status).toBe(500);
    expect(res.body.error).toBe('INTERNAL_ERROR');
    expect(consoleErrorSpy).toHaveBeenCalled();
  });

  it('23505 de outra constraint não vira 409 de username', async () => {
    pool.query.mockRejectedValueOnce(erroUnique('outra_constraint_key'));

    const res = await patchMe({ username: 'livre_123' });

    expect(res.status).toBe(500);
    expect(res.body.error).toBe('INTERNAL_ERROR');
  });

  it('username livre é salvo com 1 ida ao banco e responde 200 com os contadores', async () => {
    pool.query.mockResolvedValueOnce({
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
        seguidores: '7',
        seguindo: '2',
      }],
    });

    const res = await patchMe({ username: 'livre_123' });

    expect(res.status).toBe(200);
    expect(res.body.data.username).toBe('livre_123');
    expect(res.body.data.seguidores).toBe(7);
    expect(res.body.data.seguindo).toBe(2);
    expect(pool.query.mock.calls.length).toBe(1);
    const [sql, valores] = chamadaUpdate();
    expect(sql).toContain('username =');
    expect(sql).toMatch(/WHERE id = \$2\b/);
    expect(sql).toContain('AS seguidores');
    expect(sql).toContain('AS seguindo');
    expect(valores).toEqual(['livre_123', 'user-1']);
  });
});
