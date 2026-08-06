jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

describe('POST/DELETE /v1/publicacoes/:id/curtir', () => {
  beforeEach(() => {
    pool.query.mockReset();
  });

  it('é idempotente: chamar POST duas vezes seguidas não gera erro nem duplica', async () => {
    pool.query.mockResolvedValue({ rows: [] });
    const token = gerarToken('user-1');

    const r1 = await request(app)
      .post('/v1/publicacoes/pub-1/curtir')
      .set('Authorization', `Bearer ${token}`);
    const r2 = await request(app)
      .post('/v1/publicacoes/pub-1/curtir')
      .set('Authorization', `Bearer ${token}`);

    expect(r1.status).toBe(201);
    expect(r1.body).toEqual({ data: { curtido: true } });
    expect(r2.status).toBe(201);
    expect(r2.body).toEqual({ data: { curtido: true } });

    for (const call of pool.query.mock.calls) {
      expect(call[0]).toMatch(/ON CONFLICT DO NOTHING/);
      expect(call[1]).toEqual(['user-1', 'pub-1']);
    }
  });

  it('DELETE retorna curtido: false', async () => {
    pool.query.mockResolvedValue({ rows: [] });
    const token = gerarToken('user-1');

    const res = await request(app)
      .delete('/v1/publicacoes/pub-1/curtir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ data: { curtido: false } });
    expect(pool.query).toHaveBeenCalledWith(
      'DELETE FROM curtidas WHERE usuario_id = $1 AND publicacao_id = $2',
      ['user-1', 'pub-1']
    );
  });

  it('POST sem autenticação retorna 401', async () => {
    const res = await request(app).post('/v1/publicacoes/pub-1/curtir');
    expect(res.status).toBe(401);
    expect(pool.query).not.toHaveBeenCalled();
  });

  it('POST em publicação inexistente (violação de FK) retorna 404', async () => {
    const erroFk = new Error('violates foreign key constraint');
    erroFk.code = '23503';
    pool.query.mockRejectedValue(erroFk);
    const token = gerarToken('user-1');

    const res = await request(app)
      .post('/v1/publicacoes/nao-existe/curtir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('PUBLICACAO_NAO_ENCONTRADA');
  });
});
