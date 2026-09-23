process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const token = gerarToken('user-1');

// Posição de de_volta nos parâmetros do INSERT de notificacoes ($9).
const IDX_DE_VOLTA = 8;

function insertsNotificacao() {
  return pool.query.mock.calls.filter(([sql]) => sql.includes('INSERT INTO notificacoes'));
}

describe('POST /v1/usuarios/:id/seguir', () => {
  beforeEach(() => pool.query.mockReset());

  it('201 follow novo sem reciprocidade notifica com de_volta = false', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ id: 'user-2' }] }) // alvo existe
      .mockResolvedValueOnce({ rows: [{ seguidor_id: 'user-1' }] }) // INSERT pivot
      .mockResolvedValueOnce({ rows: [] }) // SELECT recíproco
      .mockResolvedValueOnce({ rows: [{ nome: 'Fulano', username: 'fulano' }] }) // remetente
      .mockResolvedValueOnce({ rows: [] }); // INSERT notificacoes

    const res = await request(app)
      .post('/v1/usuarios/user-2/seguir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(201);
    const inserts = insertsNotificacao();
    expect(inserts).toHaveLength(1);
    expect(inserts[0][0]).toMatch(/de_volta/);
    expect(inserts[0][1][IDX_DE_VOLTA]).toBe(false);
  });

  it('201 seguir de volta notifica com de_volta = true', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ id: 'user-2' }] })
      .mockResolvedValueOnce({ rows: [{ seguidor_id: 'user-1' }] })
      .mockResolvedValueOnce({ rows: [{ '?column?': 1 }] })
      .mockResolvedValueOnce({ rows: [{ nome: 'Fulano', username: 'fulano' }] })
      .mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/v1/usuarios/user-2/seguir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(201);
    const inserts = insertsNotificacao();
    expect(inserts).toHaveLength(1);
    expect(inserts[0][1][IDX_DE_VOLTA]).toBe(true);
  });

  it('201 quando já seguia não gera notificação nova', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ id: 'user-2' }] })
      .mockResolvedValueOnce({ rows: [] }); // ON CONFLICT DO NOTHING

    const res = await request(app)
      .post('/v1/usuarios/user-2/seguir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(201);
    expect(res.body).toEqual({ data: { message: 'Usuário seguido com sucesso.' } });
    expect(insertsNotificacao()).toHaveLength(0);
    expect(pool.query).toHaveBeenCalledTimes(2);
  });

  it('400 ao tentar seguir a si mesmo', async () => {
    const res = await request(app)
      .post('/v1/usuarios/user-1/seguir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(400);
    expect(pool.query).not.toHaveBeenCalled();
  });

  it('404 quando o alvo não existe', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/v1/usuarios/user-x/seguir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
    const inserts = pool.query.mock.calls.filter(([sql]) => sql.includes('INSERT'));
    expect(inserts).toHaveLength(0);
  });
});

describe('GET /v1/notificacoes — deVolta', () => {
  beforeEach(() => pool.query.mockReset());

  const base = {
    id: 'notif-1',
    para: 'user-1',
    de_id: 'user-2',
    de: 'Fulano',
    de_username: 'fulano',
    de_foto: null,
    ja_sigo_de: true,
    tipo: 'seguindo',
    texto: null,
    post_id: null,
    chat_id: null,
    lida: false,
    criado_em: '2026-01-01T00:00:00.000Z',
  };

  it('devolve deVolta true quando a linha tem de_volta true e false quando a coluna falta', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ ...base, de_volta: true }, { ...base, id: 'notif-2' }] })
      .mockResolvedValueOnce({ rows: [{ count: '2' }] })
      .mockResolvedValueOnce({ rows: [{ count: '2' }] });

    const res = await request(app)
      .get('/v1/notificacoes')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data[0].deVolta).toBe(true);
    expect(res.body.data[1].deVolta).toBe(false);
  });
});
