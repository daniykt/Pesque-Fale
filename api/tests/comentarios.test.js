jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

// Linha que a CTE do criar devolve: comentário + autor + autor da publicação.
function linhaComentario(overrides = {}) {
  return {
    id: 'com-1',
    publicacao_id: 'pub-1',
    autor_id: 'user-1',
    texto: 'Boa pescaria!',
    criado_em: '2026-01-01T00:00:00.000Z',
    autor_nome: 'Fulano',
    autor_username: 'fulano',
    autor_foto: null,
    publicacao_autor_id: 'outro-user',
    ...overrides,
  };
}

function insertsNotificacao() {
  return pool.query.mock.calls.filter(([sql]) => sql.includes('INSERT INTO notificacoes'));
}

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
      .mockResolvedValueOnce({ rows: [linhaComentario()] }) // CTE comentário
      .mockResolvedValueOnce({ rows: [] }); // CTE notificacoes

    const token = gerarToken('user-1');
    const res = await request(app)
      .post('/v1/publicacoes/pub-1/comentarios')
      .set('Authorization', `Bearer ${token}`)
      .send({ texto: 'Boa pescaria!' });

    expect(res.status).toBe(201);
    expect(res.body.data).toEqual({
      id: 'com-1',
      publicacaoId: 'pub-1',
      autorId: 'user-1',
      autorNome: 'Fulano',
      autorUsername: 'fulano',
      texto: 'Boa pescaria!',
      criadoEm: '2026-01-01T00:00:00.000Z',
    });
  });

  it('cria com 2 idas ao banco e notifica o autor da publicação', async () => {
    const texto = 'x'.repeat(150);
    pool.query
      .mockResolvedValueOnce({ rows: [linhaComentario({ texto })] })
      .mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/v1/publicacoes/pub-1/comentarios')
      .set('Authorization', `Bearer ${gerarToken('user-1')}`)
      .send({ texto });

    expect(res.status).toBe(201);
    expect(pool.query.mock.calls.length).toBe(2);
    const [sql, params] = pool.query.mock.calls[0];
    expect(sql).toContain('INSERT INTO comentarios');
    expect(params).toEqual(['pub-1', 'user-1', texto]);
    const notificacoes = insertsNotificacao();
    expect(notificacoes).toHaveLength(1);
    // para, deId, tipo, texto (cortado em 100), postId
    expect(notificacoes[0][1].slice(0, 5)).toEqual([
      'outro-user', 'user-1', 'comentario', 'x'.repeat(100), 'pub-1',
    ]);
  });

  it('comentar a própria publicação não notifica (1 ida ao banco)', async () => {
    pool.query.mockResolvedValueOnce({ rows: [linhaComentario({ publicacao_autor_id: 'user-1' })] });

    const res = await request(app)
      .post('/v1/publicacoes/pub-1/comentarios')
      .set('Authorization', `Bearer ${gerarToken('user-1')}`)
      .send({ texto: 'Boa pescaria!' });

    expect(res.status).toBe(201);
    expect(pool.query.mock.calls.length).toBe(1);
    expect(insertsNotificacao()).toHaveLength(0);
  });

  it('publicação inexistente (violação de FK) retorna 404 PUBLICACAO_NAO_ENCONTRADA', async () => {
    pool.query.mockRejectedValueOnce(
      Object.assign(new Error('violates foreign key constraint'), { code: '23503' })
    );

    const res = await request(app)
      .post('/v1/publicacoes/nao-existe/comentarios')
      .set('Authorization', `Bearer ${gerarToken('user-1')}`)
      .send({ texto: 'Boa pescaria!' });

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('PUBLICACAO_NAO_ENCONTRADA');
    expect(pool.query.mock.calls.length).toBe(1);
    expect(insertsNotificacao()).toHaveLength(0);
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