jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

function linhaPublicacao(overrides = {}) {
  return {
    id: 'pub-1',
    autor_id: 'user-2',
    ponto_id: null,
    descricao: 'Peguei um tucunaré',
    imagem_url: null,
    local_texto: 'Rio Mogi',
    avaliacao_nota: null,
    tags: ['tucunare'],
    curtidas_count: 3,
    comentarios_count: 1,
    criado_em: '2026-01-01T00:00:00.000Z',
    atualizado_em: '2026-01-01T00:00:00.000Z',
    autor_nome: 'Fulano',
    autor_username: 'fulano',
    autor_foto: null,
    ...overrides,
  };
}

describe('GET /v1/publicacoes', () => {
  beforeEach(() => {
    pool.query.mockReset();
  });

  it('sem autenticação: jaCurtiu é sempre false', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [linhaPublicacao()] })
      .mockResolvedValueOnce({ rows: [{ count: '1' }] });

    const res = await request(app).get('/v1/publicacoes');

    expect(res.status).toBe(200);
    expect(res.body.data[0].jaCurtiu).toBe(false);
    expect(res.body.data[0].autorNome).toBe('Fulano');
    expect(res.body.data[0].tags).toEqual(['tucunare']);
  });

  it('com autenticação: jaCurtiu reflete o valor retornado pelo banco', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [linhaPublicacao({ ja_curtiu: true })] })
      .mockResolvedValueOnce({ rows: [{ count: '1' }] });

    const token = gerarToken('user-1');
    const res = await request(app)
      .get('/v1/publicacoes')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data[0].jaCurtiu).toBe(true);

    const [queryText, params] = pool.query.mock.calls[0];
    expect(queryText).toMatch(/EXISTS \(SELECT 1 FROM curtidas/);
    expect(params).toContain('user-1');
  });

  it('?seguindo=true sem autenticação retorna 401', async () => {
    const res = await request(app).get('/v1/publicacoes?seguindo=true');
    expect(res.status).toBe(401);
    expect(pool.query).not.toHaveBeenCalled();
  });

  it('?seguindo=true com autenticação filtra por usuario_seguidores', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [linhaPublicacao({ ja_curtiu: false })] })
      .mockResolvedValueOnce({ rows: [{ count: '1' }] });

    const token = gerarToken('user-1');
    const res = await request(app)
      .get('/v1/publicacoes?seguindo=true')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);

    const [queryText, params] = pool.query.mock.calls[0];
    expect(queryText).toMatch(/autor_id IN \(SELECT seguido_id FROM usuario_seguidores WHERE seguidor_id/);
    expect(params[0]).toBe('user-1');

    const [countQueryText, countParams] = pool.query.mock.calls[1];
    expect(countQueryText).toMatch(/usuario_seguidores/);
    expect(countParams).toEqual(['user-1']);
  });
});
