jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');

describe('GET /v1/pontos?ordem=nota_desc', () => {
  beforeEach(() => {
    pool.query.mockReset();
    pool.query.mockResolvedValue({ rows: [] });
  });

  it('ordena por avg_nota DESC quando ordem=nota_desc', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: [{ count: '0' }] });

    const res = await request(app).get('/v1/pontos?ordem=nota_desc');

    expect(res.status).toBe(200);
    const [queryText] = pool.query.mock.calls[0];
    expect(queryText).toMatch(/ORDER BY avg_nota DESC NULLS LAST, total_avaliacoes DESC/);
  });

  it('mantém a ordenação padrão por criado_em quando ordem não é informado', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: [{ count: '0' }] });

    await request(app).get('/v1/pontos');

    const [queryText] = pool.query.mock.calls[0];
    expect(queryText).toMatch(/ORDER BY criado_em DESC/);
  });
});
