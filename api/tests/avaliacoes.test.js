process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const token = gerarToken('user-1');

const avaliacaoMock = {
  id: 'aval-1',
  usuario_id: 'user-1',
  ponto_id: 'ponto-1',
  nota: 4.5,
  comentario: 'Ótimo local!',
  criado_em: '2026-01-01T00:00:00.000Z',
  atualizado_em: '2026-01-01T00:00:00.000Z',
};

describe('POST /v1/pontos/:pontoId/avaliacoes', () => {
  beforeEach(() => pool.query.mockReset());

  it('201 com nota válida', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ id: 'ponto-1' }] })
      .mockResolvedValueOnce({ rows: [avaliacaoMock] });

    const res = await request(app)
      .post('/v1/pontos/ponto-1/avaliacoes')
      .set('Authorization', `Bearer ${token}`)
      .send({ nota: 4.5, comentario: 'Ótimo local!' });

    expect(res.status).toBe(201);
    expect(res.body.data.nota).toBe(4.5);
  });

  it('400 quando nota não é informada', async () => {
    const res = await request(app)
      .post('/v1/pontos/ponto-1/avaliacoes')
      .set('Authorization', `Bearer ${token}`)
      .send({ comentario: 'Sem nota' });

    expect(res.status).toBe(400);
    expect(res.body.details[0].campo).toBe('nota');
  });

  it('400 quando nota é menor que 1', async () => {
    const res = await request(app)
      .post('/v1/pontos/ponto-1/avaliacoes')
      .set('Authorization', `Bearer ${token}`)
      .send({ nota: 0.5 });

    expect(res.status).toBe(400);
    expect(res.body.details[0].campo).toBe('nota');
  });

  it('400 quando nota é maior que 5', async () => {
    const res = await request(app)
      .post('/v1/pontos/ponto-1/avaliacoes')
      .set('Authorization', `Bearer ${token}`)
      .send({ nota: 6 });

    expect(res.status).toBe(400);
    expect(res.body.details[0].campo).toBe('nota');
  });

  it('404 quando ponto não existe', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/v1/pontos/nao-existe/avaliacoes')
      .set('Authorization', `Bearer ${token}`)
      .send({ nota: 4 });

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('PONTO_NAO_ENCONTRADO');
  });

  it('409 quando usuário já avaliou o ponto (UNIQUE constraint)', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ id: 'ponto-1' }] })
      .mockRejectedValueOnce({ code: '23505' });

    const res = await request(app)
      .post('/v1/pontos/ponto-1/avaliacoes')
      .set('Authorization', `Bearer ${token}`)
      .send({ nota: 3 });

    expect(res.status).toBe(409);
    expect(res.body.error).toBe('AVALIACAO_JA_EXISTE');
  });

  it('401 sem token', async () => {
    const res = await request(app)
      .post('/v1/pontos/ponto-1/avaliacoes')
      .send({ nota: 4 });

    expect(res.status).toBe(401);
  });
});

describe('GET /v1/pontos/:pontoId/avaliacoes', () => {
  beforeEach(() => pool.query.mockReset());

  it('200 com lista paginada', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ id: 'ponto-1' }] })
      .mockResolvedValueOnce({ rows: [{ ...avaliacaoMock, usuario_nome: 'Fulano', usuario_username: 'fulano', usuario_foto: null }] })
      .mockResolvedValueOnce({ rows: [{ count: '1' }] });

    const res = await request(app).get('/v1/pontos/ponto-1/avaliacoes');

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.meta.total).toBe(1);
  });

  it('404 quando ponto não existe', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app).get('/v1/pontos/nao-existe/avaliacoes');

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('PONTO_NAO_ENCONTRADO');
  });
});

describe('PATCH /v1/pontos/:pontoId/avaliacoes/minha', () => {
  beforeEach(() => pool.query.mockReset());

  it('200 ao atualizar nota', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ id: 'aval-1' }] })
      .mockResolvedValueOnce({ rows: [{ ...avaliacaoMock, nota: 5.0 }] });

    const res = await request(app)
      .patch('/v1/pontos/ponto-1/avaliacoes/minha')
      .set('Authorization', `Bearer ${token}`)
      .send({ nota: 5.0 });

    expect(res.status).toBe(200);
    expect(res.body.data.nota).toBe(5.0);
  });

  it('404 quando avaliação não existe', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .patch('/v1/pontos/ponto-1/avaliacoes/minha')
      .set('Authorization', `Bearer ${token}`)
      .send({ nota: 4 });

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('AVALIACAO_NAO_ENCONTRADA');
  });
});

describe('DELETE /v1/pontos/:pontoId/avaliacoes/minha', () => {
  beforeEach(() => pool.query.mockReset());

  it('204 ao deletar avaliação', async () => {
    pool.query.mockResolvedValueOnce({ rows: [{ id: 'aval-1' }] });

    const res = await request(app)
      .delete('/v1/pontos/ponto-1/avaliacoes/minha')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(204);
  });

  it('404 quando avaliação não existe', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .delete('/v1/pontos/ponto-1/avaliacoes/minha')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('AVALIACAO_NAO_ENCONTRADA');
  });
});