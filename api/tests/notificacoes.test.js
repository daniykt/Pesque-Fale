process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const token = gerarToken('user-1');

const notificacaoMock = {
  id: 'notif-1',
  para: 'user-2',
  de_id: 'user-1',
  de: 'Fulano',
  de_username: 'fulano',
  de_foto: null,
  ja_sigo_de: false,
  tipo: 'curtida',
  texto: null,
  post_id: 'pub-1',
  chat_id: null,
  lida: false,
  criado_em: '2026-01-01T00:00:00.000Z',
};

describe('GET /v1/notificacoes', () => {
  beforeEach(() => pool.query.mockReset());

  it('200 retorna lista paginada com naoLidas no meta', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [notificacaoMock] })
      .mockResolvedValueOnce({ rows: [{ count: '1' }] })
      .mockResolvedValueOnce({ rows: [{ count: '1' }] });

    const res = await request(app)
      .get('/v1/notificacoes')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.meta).toHaveProperty('naoLidas');
  });

  it('retorna deFoto e jaSigoDe no shape da notificação', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [notificacaoMock] })
      .mockResolvedValueOnce({ rows: [{ count: '1' }] })
      .mockResolvedValueOnce({ rows: [{ count: '1' }] });

    const res = await request(app)
      .get('/v1/notificacoes')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data[0]).toHaveProperty('deFoto');
    expect(res.body.data[0]).toHaveProperty('jaSigoDe');
  });

  it('401 sem token', async () => {
    const res = await request(app).get('/v1/notificacoes');
    expect(res.status).toBe(401);
  });
});

describe('GET /v1/notificacoes/nao-lidas', () => {
  beforeEach(() => pool.query.mockReset());

  it('200 retorna contagem de não lidas', async () => {
    pool.query.mockResolvedValueOnce({ rows: [{ count: '3' }] });

    const res = await request(app)
      .get('/v1/notificacoes/nao-lidas')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data.naoLidas).toBe(3);
  });
});

describe('PATCH /v1/notificacoes/:id/lida', () => {
  beforeEach(() => pool.query.mockReset());

  it('200 marca notificação como lida', async () => {
    pool.query.mockResolvedValueOnce({
      rows: [{ ...notificacaoMock, lida: true }],
    });

    const res = await request(app)
      .patch('/v1/notificacoes/notif-1/lida')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data.lida).toBe(true);
  });

  it('404 quando notificação não existe', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .patch('/v1/notificacoes/nao-existe/lida')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('NOTIFICACAO_NAO_ENCONTRADA');
  });
});

describe('PATCH /v1/notificacoes/todas-lidas', () => {
  beforeEach(() => pool.query.mockReset());

  it('204 marca todas como lidas', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .patch('/v1/notificacoes/todas-lidas')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(204);
  });
});

describe('Gatilhos automáticos de notificação', () => {
  beforeEach(() => pool.query.mockReset());

  it('seguir dispara notificação tipo seguindo', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ id: 'user-2' }] })
      .mockResolvedValueOnce({ rows: [{ seguidor_id: 'user-1' }] })
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: [{ nome: 'Fulano', username: 'fulano' }] })
      .mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/v1/usuarios/user-2/seguir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(201);

    const insertsNotif = pool.query.mock.calls.filter(([sql]) =>
      sql.includes('INSERT INTO notificacoes')
    );
    expect(insertsNotif.length).toBeGreaterThan(0);
  });

  it('curtir dispara notificação tipo curtida', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: [{ autor_id: 'user-2' }] })
      .mockResolvedValueOnce({ rows: [{ nome: 'Fulano', username: 'fulano' }] })
      .mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/v1/publicacoes/pub-1/curtir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(201);

    const insertsNotif = pool.query.mock.calls.filter(([sql]) =>
      sql.includes('INSERT INTO notificacoes')
    );
    expect(insertsNotif.length).toBeGreaterThan(0);
  });

  it('comentar dispara notificação tipo comentario', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ id: 'com-1' }] })
      .mockResolvedValueOnce({
        rows: [{
          id: 'com-1',
          publicacao_id: 'pub-1',
          autor_id: 'user-1',
          texto: 'Boa pescaria!',
          criado_em: '2026-01-01T00:00:00.000Z',
          autor_nome: 'Fulano',
          autor_username: 'fulano',
          autor_foto: null,
        }],
      })
      .mockResolvedValueOnce({ rows: [{ autor_id: 'user-2' }] })
      .mockResolvedValueOnce({ rows: [{ nome: 'Fulano', username: 'fulano' }] })
      .mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/v1/publicacoes/pub-1/comentarios')
      .set('Authorization', `Bearer ${token}`)
      .send({ texto: 'Boa pescaria!' });

    expect(res.status).toBe(201);

    const insertsNotif = pool.query.mock.calls.filter(([sql]) =>
      sql.includes('INSERT INTO notificacoes')
    );
    expect(insertsNotif.length).toBeGreaterThan(0);
  });
});