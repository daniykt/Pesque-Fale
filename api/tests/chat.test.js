process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const token = gerarToken('user-1');

const conversaMock = {
  id: 'user-1_user-2',
  outro_id: 'user-2',
  outro_nome: 'Henrique',
  outro_username: 'henrique',
  outro_foto: null,
  ultima_mensagem: 'Boa pescaria!',
  ultima_mensagem_em: '2026-01-01T00:00:00.000Z',
  nao_lidas: '0',
  criado_em: '2026-01-01T00:00:00.000Z',
};

const mensagemMock = {
  id: 'msg-1',
  chat_id: 'user-1_user-2',
  user_id: 'user-1',
  nome: 'Fulano',
  texto: 'Boa pescaria!',
  status: 'enviado',
  criado_em: '2026-01-01T00:00:00.000Z',
};

describe('GET /v1/chats', () => {
  beforeEach(() => pool.query.mockReset());

  it('200 retorna lista de conversas', async () => {
    pool.query.mockResolvedValueOnce({ rows: [conversaMock] });

    const res = await request(app)
      .get('/v1/chats')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0]).toHaveProperty('outroId');
    expect(res.body.data[0]).toHaveProperty('naoLidas');
  });

  it('401 sem token', async () => {
    const res = await request(app).get('/v1/chats');
    expect(res.status).toBe(401);
  });

  it('lista vazia quando não há conversas', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .get('/v1/chats')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(0);
  });
});

describe('GET /v1/chats/:chatId/mensagens', () => {
  beforeEach(() => pool.query.mockReset());

  it('200 retorna histórico paginado', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ id: 'user-1_user-2' }] })
      .mockResolvedValueOnce({ rows: [mensagemMock] })
      .mockResolvedValueOnce({ rows: [{ count: '1' }] });

    const res = await request(app)
      .get('/v1/chats/user-1_user-2/mensagens')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0]).toHaveProperty('texto');
    expect(res.body.data[0]).toHaveProperty('status');
    expect(res.body.meta).toHaveProperty('total');
  });

  it('404 quando chat não existe ou usuário não é participante', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .get('/v1/chats/nao-existe/mensagens')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('CHAT_NAO_ENCONTRADO');
  });

  it('401 sem token', async () => {
    const res = await request(app).get('/v1/chats/user-1_user-2/mensagens');
    expect(res.status).toBe(401);
  });
});