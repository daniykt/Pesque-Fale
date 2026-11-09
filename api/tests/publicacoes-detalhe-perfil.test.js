jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

// A linha do mock traz um email de propósito: mesmo que o banco o devolva,
// a resposta não pode expô-lo.
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
    autor_foto: 'https://res.cloudinary.com/foto.jpg',
    email: 'fulano@teste.com',
    ...overrides,
  };
}

function esperarFormatoDoFeed(pub) {
  expect(pub).toEqual(expect.objectContaining({
    id: 'pub-1',
    autorId: 'user-2',
    autorNome: 'Fulano',
    autorUsername: 'fulano',
    autorFoto: 'https://res.cloudinary.com/foto.jpg',
    curtidasCount: 3,
    comentariosCount: 1,
    tags: ['tucunare'],
  }));
  expect(typeof pub.jaCurtiu).toBe('boolean');
  expect(pub).not.toHaveProperty('email');
}

describe('GET /v1/publicacoes/:id', () => {
  beforeEach(() => {
    pool.query.mockReset();
  });

  it('logado com curtida: autor no formato do feed e jaCurtiu true, em 1 query', async () => {
    pool.query.mockResolvedValueOnce({ rows: [linhaPublicacao({ ja_curtiu: true })] });

    const res = await request(app)
      .get('/v1/publicacoes/pub-1')
      .set('Authorization', `Bearer ${gerarToken('user-1')}`);

    expect(res.status).toBe(200);
    esperarFormatoDoFeed(res.body.data);
    expect(res.body.data.jaCurtiu).toBe(true);

    expect(pool.query).toHaveBeenCalledTimes(1);
    const [sql, params] = pool.query.mock.calls[0];
    expect(sql).toMatch(/JOIN usuarios u ON u\.id = p\.autor_id/);
    expect(sql).toMatch(/EXISTS \(SELECT 1 FROM curtidas c WHERE c\.publicacao_id = p\.id AND c\.usuario_id = \$2\)/);
    expect(sql).not.toMatch(/u\.email/);
    expect(params).toEqual(['pub-1', 'user-1']);
  });

  it('logado sem curtida: jaCurtiu false', async () => {
    pool.query.mockResolvedValueOnce({ rows: [linhaPublicacao({ ja_curtiu: false })] });

    const res = await request(app)
      .get('/v1/publicacoes/pub-1')
      .set('Authorization', `Bearer ${gerarToken('user-1')}`);

    expect(res.status).toBe(200);
    esperarFormatoDoFeed(res.body.data);
    expect(res.body.data.jaCurtiu).toBe(false);
  });

  it('deslogado: 200 com autor, jaCurtiu false e sem EXISTS na query', async () => {
    pool.query.mockResolvedValueOnce({ rows: [linhaPublicacao({ ja_curtiu: false })] });

    const res = await request(app).get('/v1/publicacoes/pub-1');

    expect(res.status).toBe(200);
    esperarFormatoDoFeed(res.body.data);
    expect(res.body.data.jaCurtiu).toBe(false);

    expect(pool.query).toHaveBeenCalledTimes(1);
    const [sql, params] = pool.query.mock.calls[0];
    expect(sql).toMatch(/JOIN usuarios u/);
    expect(sql).toMatch(/FALSE AS ja_curtiu/);
    expect(sql).not.toMatch(/EXISTS/);
    expect(params).toEqual(['pub-1']);
  });

  it('token inválido: segue como deslogado, sem 401', async () => {
    pool.query.mockResolvedValueOnce({ rows: [linhaPublicacao({ ja_curtiu: false })] });

    const res = await request(app)
      .get('/v1/publicacoes/pub-1')
      .set('Authorization', 'Bearer token-invalido');

    expect(res.status).toBe(200);
    expect(res.body.data.jaCurtiu).toBe(false);
    expect(pool.query.mock.calls[0][1]).toEqual(['pub-1']);
  });

  it('publicação inexistente: 404 PUBLICACAO_NAO_ENCONTRADA', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .get('/v1/publicacoes/nao-existe')
      .set('Authorization', `Bearer ${gerarToken('user-1')}`);

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('PUBLICACAO_NAO_ENCONTRADA');
    expect(res.body).not.toHaveProperty('data');
  });
});

describe('GET /v1/usuarios/:id/publicacoes', () => {
  beforeEach(() => {
    pool.query.mockReset();
  });

  function mockPerfilComPublicacoes(linha) {
    pool.query
      .mockResolvedValueOnce({ rows: [{ id: 'user-2' }] }) // usuário existe
      .mockResolvedValueOnce({ rows: [linha] }) // lista
      .mockResolvedValueOnce({ rows: [{ count: '1' }] }); // total
  }

  it('logado com curtida: formato do feed, jaCurtiu true e params na ordem (perfil, logado, limit, offset)', async () => {
    mockPerfilComPublicacoes(linhaPublicacao({ ja_curtiu: true }));

    const res = await request(app)
      .get('/v1/usuarios/user-2/publicacoes?pagina=2&porPagina=10')
      .set('Authorization', `Bearer ${gerarToken('user-1')}`);

    expect(res.status).toBe(200);
    esperarFormatoDoFeed(res.body.data[0]);
    expect(res.body.data[0].jaCurtiu).toBe(true);
    expect(res.body.meta).toEqual({ total: 1, pagina: 2, porPagina: 10 });

    // Mesmo número de idas ao banco de antes: existe + lista + total.
    expect(pool.query).toHaveBeenCalledTimes(3);
    const [sql, params] = pool.query.mock.calls[1];
    expect(sql).toMatch(/JOIN usuarios u ON u\.id = p\.autor_id/);
    expect(sql).toMatch(/WHERE p\.autor_id = \$1/);
    expect(sql).toMatch(/c\.usuario_id = \$2\) AS ja_curtiu/);
    expect(sql).toMatch(/LIMIT \$3 OFFSET \$4/);
    expect(sql).not.toMatch(/u\.email/);
    expect(params).toEqual(['user-2', 'user-1', 10, 10]);
  });

  it('logado sem curtida: jaCurtiu false', async () => {
    mockPerfilComPublicacoes(linhaPublicacao({ ja_curtiu: false }));

    const res = await request(app)
      .get('/v1/usuarios/user-2/publicacoes')
      .set('Authorization', `Bearer ${gerarToken('user-1')}`);

    expect(res.status).toBe(200);
    esperarFormatoDoFeed(res.body.data[0]);
    expect(res.body.data[0].jaCurtiu).toBe(false);
    expect(pool.query.mock.calls[1][1]).toEqual(['user-2', 'user-1', 12, 0]);
  });

  it('deslogado: 200 com autor, jaCurtiu false e params (perfil, limit, offset)', async () => {
    mockPerfilComPublicacoes(linhaPublicacao({ ja_curtiu: false }));

    const res = await request(app).get('/v1/usuarios/user-2/publicacoes');

    expect(res.status).toBe(200);
    esperarFormatoDoFeed(res.body.data[0]);
    expect(res.body.data[0].jaCurtiu).toBe(false);

    expect(pool.query).toHaveBeenCalledTimes(3);
    const [sql, params] = pool.query.mock.calls[1];
    expect(sql).toMatch(/JOIN usuarios u/);
    expect(sql).toMatch(/FALSE AS ja_curtiu/);
    expect(sql).not.toMatch(/EXISTS/);
    expect(sql).toMatch(/LIMIT \$2 OFFSET \$3/);
    expect(params).toEqual(['user-2', 12, 0]);
  });

  it('usuário inexistente: 404 sem consultar as publicações', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await request(app).get('/v1/usuarios/nao-existe/publicacoes');

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('USUARIO_NAO_ENCONTRADO');
    expect(pool.query).toHaveBeenCalledTimes(1);
  });
});
