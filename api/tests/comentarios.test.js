jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

describe('POST /v1/publicacoes/:id/comentarios', () => {
  beforeEach(() => {
    pool.query.mockReset();
  });

  it('rejeita texto vazio com 400', async () => {
    const token = gerarToken('user-1');
    const res = await request(app)
      .post('/v1/publicacoes/pub-1/comentarios')
      .set('Authorization', `Bearer ${token}`)
      .send({ texto: '' });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('VALIDATION_ERROR');
    expect(pool.query).not.toHaveBeenCalled();
  });

  it('rejeita texto com mais de 500 caracteres com 400', async () => {
    const token = gerarToken('user-1');
    const res = await request(app)
      .post('/v1/publicacoes/pub-1/comentarios')
      .set('Authorization', `Bearer ${token}`)
      .send({ texto: 'a'.repeat(501) });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('VALIDATION_ERROR');
  });

  it('aceita texto válido e retorna o comentário criado com autor', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ id: 'com-1' }] })
      .mockResolvedValueOnce({
        rows: [
          {
            id: 'com-1',
            publicacao_id: 'pub-1',
            autor_id: 'user-1',
            texto: 'Boa pescaria!',
            criado_em: '2026-01-01T00:00:00.000Z',
            autor_nome: 'Fulano',
            autor_username: 'fulano',
            autor_foto: null,
          },
        ],
      })
      .mockResolvedValueOnce({ rows: [{ autor_id: 'outro-user' }] })
      .mockResolvedValueOnce({ rows: [] });

    const token = gerarToken('user-1');
    const res = await request(app)
      .post('/v1/publicacoes/pub-1/comentarios')
      .set('Authorization', `Bearer ${token}`)
      .send({ texto: 'Boa pescaria!' });

    expect(res.status).toBe(201);
    expect(res.body.data.texto).toBe('Boa pescaria!');
    expect(res.body.data.autorNome).toBe('Fulano');
  });
});

describe('DELETE /v1/comentarios/:id', () => {
  beforeEach(() => {
    pool.query.mockReset();
  });

  it('retorna 403 ao tentar deletar comentário de outro usuário', async () => {
    pool.query.mockResolvedValueOnce({ rows: [{ autor_id: 'outro-usuario' }] });

    const token = gerarToken('user-1');
    const res = await request(app)
      .delete('/v1/comentarios/com-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
    expect(res.body.error).toBe('FORBIDDEN');
  });

  it('permite ao autor deletar seu próprio comentário', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ autor_id: 'user-1' }] })
      .mockResolvedValueOnce({ rows: [] });

    const token = gerarToken('user-1');
    const res = await request(app)
      .delete('/v1/comentarios/com-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(204);
  });
});