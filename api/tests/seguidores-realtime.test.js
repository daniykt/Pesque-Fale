process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));
jest.mock('../src/config/socket-emitter', () => ({
  init: jest.fn(),
  emitToUser: jest.fn(),
}));

const request = require('supertest');
const pool = require('../src/config/database');
const { emitToUser } = require('../src/config/socket-emitter');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const token = gerarToken('user-a');

// Roteia o pool.query pelo SQL, sem depender da ordem exata das chamadas.
// `mudou` decide se o INSERT/DELETE do pivot devolve linha (follow/unfollow
// real) ou vem vazio (idempotente); `falharContagem` simula erro pós-mudança.
function mockBanco({ mudou = true, total = '42', falharContagem = false } = {}) {
  pool.query.mockImplementation(async (sql) => {
    if (sql.includes('SELECT id FROM usuarios')) return { rows: [{ id: 'user-b' }] };
    if (sql.includes('INSERT INTO usuario_seguidores') || sql.includes('DELETE FROM usuario_seguidores')) {
      return { rows: mudou ? [{ seguidor_id: 'user-a' }] : [] };
    }
    if (sql.includes('SELECT COUNT(*) FROM usuario_seguidores')) {
      if (falharContagem) throw new Error('conexão caiu');
      return { rows: [{ count: total }] };
    }
    if (sql.includes('SELECT nome, username FROM usuarios')) {
      return { rows: [{ nome: 'Fulano', username: 'fulano' }] };
    }
    return { rows: [] };
  });
}

function emitsDe(evento) {
  return emitToUser.mock.calls.filter(([, e]) => e === evento);
}

describe('seguidor_adicionado', () => {
  beforeEach(() => {
    pool.query.mockReset();
    emitToUser.mockReset();
  });

  it('follow novo emite pro seguido com o total autoritativo do banco', async () => {
    mockBanco({ total: '42' });

    const res = await request(app)
      .post('/v1/usuarios/user-b/seguir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(201);
    const emits = emitsDe('seguidor_adicionado');
    expect(emits).toHaveLength(1);
    expect(emits[0]).toEqual([
      'user-b',
      'seguidor_adicionado',
      { totalSeguidores: 42, seguidorId: 'user-a', acao: 'adicionado' },
    ]);
  });

  it('follow idempotente (já seguia) não emite nada', async () => {
    mockBanco({ mudou: false });

    const res = await request(app)
      .post('/v1/usuarios/user-b/seguir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(201);
    expect(emitToUser).not.toHaveBeenCalled();
  });

  it('erro na contagem não quebra o response do follow', async () => {
    mockBanco({ falharContagem: true });
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});

    const res = await request(app)
      .post('/v1/usuarios/user-b/seguir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(201);
    expect(res.body).toEqual({ data: { message: 'Usuário seguido com sucesso.' } });
    expect(emitsDe('seguidor_adicionado')).toHaveLength(0);
    expect(erro).toHaveBeenCalledWith(
      '[usuarios] erro ao emitir seguidor_adicionado:',
      expect.any(Error)
    );

    erro.mockRestore();
  });

  it('emit que lança não quebra o response do follow', async () => {
    mockBanco();
    emitToUser.mockImplementation((_, evento) => {
      if (evento === 'seguidor_adicionado') throw new Error('socket caiu');
    });
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});

    const res = await request(app)
      .post('/v1/usuarios/user-b/seguir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(201);
    expect(erro).toHaveBeenCalledWith(
      '[usuarios] erro ao emitir seguidor_adicionado:',
      expect.any(Error)
    );

    erro.mockRestore();
  });
});

describe('seguidor_removido', () => {
  beforeEach(() => {
    pool.query.mockReset();
    emitToUser.mockReset();
  });

  it('DELETE pede RETURNING pra distinguir unfollow real do idempotente', async () => {
    mockBanco();

    await request(app)
      .delete('/v1/usuarios/user-b/seguir')
      .set('Authorization', `Bearer ${token}`);

    const deletes = pool.query.mock.calls.filter(([sql]) => sql.includes('DELETE FROM usuario_seguidores'));
    expect(deletes).toHaveLength(1);
    expect(deletes[0][0]).toMatch(/RETURNING seguidor_id/);
    expect(deletes[0][1]).toEqual(['user-a', 'user-b']);
  });

  it('unfollow real emite pro seguido com o total autoritativo do banco', async () => {
    mockBanco({ total: '41' });

    const res = await request(app)
      .delete('/v1/usuarios/user-b/seguir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(204);
    expect(emitToUser).toHaveBeenCalledTimes(1);
    expect(emitToUser).toHaveBeenCalledWith('user-b', 'seguidor_removido', {
      totalSeguidores: 41,
      seguidorId: 'user-a',
      acao: 'removido',
    });
  });

  it('unfollow idempotente (não seguia) responde 204 e não emite', async () => {
    mockBanco({ mudou: false });

    const res = await request(app)
      .delete('/v1/usuarios/user-b/seguir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(204);
    expect(emitToUser).not.toHaveBeenCalled();
    const contagens = pool.query.mock.calls.filter(([sql]) => sql.includes('COUNT(*)'));
    expect(contagens).toHaveLength(0);
  });

  it('erro na contagem não quebra o response do unfollow', async () => {
    mockBanco({ falharContagem: true });
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});

    const res = await request(app)
      .delete('/v1/usuarios/user-b/seguir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(204);
    expect(emitToUser).not.toHaveBeenCalled();
    expect(erro).toHaveBeenCalledWith(
      '[usuarios] erro ao emitir seguidor_removido:',
      expect.any(Error)
    );

    erro.mockRestore();
  });
});
