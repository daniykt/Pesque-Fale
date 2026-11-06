jest.mock('../src/config/database', () => ({ query: jest.fn() }));
jest.mock('../src/config/socket-emitter', () => ({
  init: jest.fn(),
  emitToUser: jest.fn(),
  emitToFeed: jest.fn(),
}));

const request = require('supertest');
const pool = require('../src/config/database');
const { emitToFeed } = require('../src/config/socket-emitter');
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
    comentarios_count: 4,
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
    pool.query.mockResolvedValueOnce({
      rows: [{ autor_id: 'outro-usuario', publicacao_id: 'pub-1', comentarios_count: 3 }],
    });

    const token = gerarToken('user-1');
    const res = await request(app)
      .delete('/v1/comentarios/com-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
    expect(res.body.error).toBe('FORBIDDEN');
  });

  it('permite ao autor deletar seu próprio comentário', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ autor_id: 'user-1', publicacao_id: 'pub-1', comentarios_count: 3 }] })
      .mockResolvedValueOnce({ rows: [] });

    const token = gerarToken('user-1');
    const res = await request(app)
      .delete('/v1/comentarios/com-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(204);
  });
});

describe('publicacao_comentarios', () => {
  const token = gerarToken('user-1');

  beforeEach(() => {
    pool.query.mockReset();
    emitToFeed.mockReset();
  });

  function comentar(texto = 'Boa pescaria!') {
    return request(app)
      .post('/v1/publicacoes/pub-1/comentarios')
      .set('Authorization', `Bearer ${token}`)
      .send({ texto });
  }

  function excluir() {
    return request(app).delete('/v1/comentarios/com-1').set('Authorization', `Bearer ${token}`);
  }

  it('criar emite o total (contador lido + 1) com quem comentou, sem ida extra', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [linhaComentario({ comentarios_count: 4 })] })
      .mockResolvedValueOnce({ rows: [] });

    await comentar();

    expect(pool.query.mock.calls.length).toBe(2);
    expect(pool.query.mock.calls[0][0]).toContain('p.comentarios_count');
    expect(emitToFeed).toHaveBeenCalledTimes(1);
    expect(emitToFeed).toHaveBeenCalledWith('publicacao_comentarios', {
      publicacaoId: 'pub-1',
      comentariosCount: 5,
      porId: 'user-1',
    });
  });

  it('criar com texto inválido não emite', async () => {
    const res = await comentar('');

    expect(res.status).toBe(400);
    expect(emitToFeed).not.toHaveBeenCalled();
  });

  it('criar em publicação inexistente não emite', async () => {
    pool.query.mockRejectedValueOnce(
      Object.assign(new Error('violates foreign key constraint'), { code: '23503' })
    );

    const res = await comentar();

    expect(res.status).toBe(404);
    expect(emitToFeed).not.toHaveBeenCalled();
  });

  it('falha no emit ao criar só loga: mantém o 201 e a notificação', async () => {
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});
    pool.query
      .mockResolvedValueOnce({ rows: [linhaComentario()] })
      .mockResolvedValueOnce({ rows: [] });
    emitToFeed.mockImplementation(() => {
      throw new Error('socket caiu');
    });

    const res = await comentar();

    expect(res.status).toBe(201);
    expect(res.body.data.id).toBe('com-1');
    expect(insertsNotificacao()).toHaveLength(1);
    expect(erro).toHaveBeenCalledWith(
      '[comentarios] erro ao emitir publicacao_comentarios:',
      expect.any(Error)
    );
    erro.mockRestore();
  });

  it('excluir emite o total (contador lido - 1) depois do DELETE, com 2 idas ao banco', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ autor_id: 'user-1', publicacao_id: 'pub-1', comentarios_count: 3 }] })
      .mockResolvedValueOnce({ rows: [] });

    const res = await excluir();

    expect(res.status).toBe(204);
    expect(pool.query.mock.calls.length).toBe(2);
    const [sqlSelect, paramsSelect] = pool.query.mock.calls[0];
    expect(sqlSelect).toMatch(/JOIN publicacoes p ON p\.id = c\.publicacao_id/);
    expect(sqlSelect).toContain('p.comentarios_count');
    expect(paramsSelect).toEqual(['com-1']);
    expect(pool.query.mock.calls[1][0]).toContain('DELETE FROM comentarios');
    expect(emitToFeed).toHaveBeenCalledWith('publicacao_comentarios', {
      publicacaoId: 'pub-1',
      comentariosCount: 2,
      porId: 'user-1',
    });
    expect(pool.query.mock.invocationCallOrder[1]).toBeLessThan(emitToFeed.mock.invocationCallOrder[0]);
  });

  it('excluir nunca emite contador negativo', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ autor_id: 'user-1', publicacao_id: 'pub-1', comentarios_count: 0 }] })
      .mockResolvedValueOnce({ rows: [] });

    await excluir();

    expect(emitToFeed).toHaveBeenCalledWith(
      'publicacao_comentarios',
      expect.objectContaining({ comentariosCount: 0 })
    );
  });

  it('excluir comentário inexistente (404) não emite', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await excluir();

    expect(res.status).toBe(404);
    expect(emitToFeed).not.toHaveBeenCalled();
  });

  it('excluir comentário de outra pessoa (403) não emite', async () => {
    pool.query.mockResolvedValueOnce({
      rows: [{ autor_id: 'outra-pessoa', publicacao_id: 'pub-1', comentarios_count: 3 }],
    });

    const res = await excluir();

    expect(res.status).toBe(403);
    expect(emitToFeed).not.toHaveBeenCalled();
  });

  it('erro no DELETE do comentário (500) não emite', async () => {
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});
    pool.query
      .mockResolvedValueOnce({ rows: [{ autor_id: 'user-1', publicacao_id: 'pub-1', comentarios_count: 3 }] })
      .mockRejectedValueOnce(new Error('banco fora'));

    const res = await excluir();

    expect(res.status).toBe(500);
    expect(emitToFeed).not.toHaveBeenCalled();
    erro.mockRestore();
  });

  it('falha no emit ao excluir só loga e mantém o 204', async () => {
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});
    pool.query
      .mockResolvedValueOnce({ rows: [{ autor_id: 'user-1', publicacao_id: 'pub-1', comentarios_count: 3 }] })
      .mockResolvedValueOnce({ rows: [] });
    emitToFeed.mockImplementation(() => {
      throw new Error('socket caiu');
    });

    const res = await excluir();

    expect(res.status).toBe(204);
    expect(erro).toHaveBeenCalledWith(
      '[comentarios] erro ao emitir publicacao_comentarios:',
      expect.any(Error)
    );
    erro.mockRestore();
  });
});
