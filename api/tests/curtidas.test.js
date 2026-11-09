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

function insertsNotificacao() {
  return pool.query.mock.calls.filter(([sql]) => sql.includes('INSERT INTO notificacoes'));
}

describe('POST/DELETE /v1/publicacoes/:id/curtir', () => {
  beforeEach(() => {
    pool.query.mockReset();
    emitToFeed.mockReset();
  });

  it('é idempotente: chamar POST duas vezes seguidas não gera erro nem duplica', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ autor_id: 'outro-user', curtidas_count: 3, nova: true }] }) // 1º POST: CTE curtida
      .mockResolvedValueOnce({ rows: [] }) // 1º POST: CTE notificacoes
      .mockResolvedValueOnce({ rows: [{ autor_id: 'outro-user', curtidas_count: 4, nova: false }] }); // 2º POST: já curtida

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
    expect(insertsNotificacao()).toHaveLength(1); // só a 1ª curtida notifica
    expect(emitToFeed).toHaveBeenCalledTimes(1); // e só a 1ª emite
  });

  it('curtida nova notifica o autor com 2 idas ao banco', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ autor_id: 'outro-user', curtidas_count: 3, nova: true }] })
      .mockResolvedValueOnce({ rows: [] });

    const res = await request(app)
      .post('/v1/publicacoes/pub-1/curtir')
      .set('Authorization', `Bearer ${gerarToken('user-1')}`);

    expect(res.status).toBe(201);
    expect(res.body).toEqual({ data: { curtido: true } });
    expect(pool.query.mock.calls.length).toBe(2);
    const [sql, params] = pool.query.mock.calls[0];
    expect(sql).toContain('INSERT INTO curtidas');
    expect(params).toEqual(['user-1', 'pub-1']);
    const notificacoes = insertsNotificacao();
    expect(notificacoes).toHaveLength(1);
    expect(notificacoes[0][1].slice(0, 3)).toEqual(['outro-user', 'user-1', 'curtida']);
  });

  it('curtir de novo uma publicação já curtida não gera notificação repetida', async () => {
    pool.query.mockResolvedValueOnce({ rows: [{ autor_id: 'outro-user', curtidas_count: 4, nova: false }] });

    const res = await request(app)
      .post('/v1/publicacoes/pub-1/curtir')
      .set('Authorization', `Bearer ${gerarToken('user-1')}`);

    expect(res.status).toBe(201);
    expect(res.body).toEqual({ data: { curtido: true } });
    expect(insertsNotificacao()).toHaveLength(0);
    expect(pool.query.mock.calls.length).toBe(1);
    expect(emitToFeed).not.toHaveBeenCalled();
  });

  it('DELETE retorna curtido: false com 1 ida ao banco', async () => {
    pool.query.mockResolvedValueOnce({ rows: [{ curtidas_count: 4, removida: true }] });
    const token = gerarToken('user-1');

    const res = await request(app)
      .delete('/v1/publicacoes/pub-1/curtir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ data: { curtido: false } });
    expect(pool.query.mock.calls.length).toBe(1);
    const [sql, params] = pool.query.mock.calls[0];
    expect(sql).toContain('DELETE FROM curtidas WHERE usuario_id = $1 AND publicacao_id = $2');
    expect(params).toEqual(['user-1', 'pub-1']);
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
    expect(pool.query.mock.calls.length).toBe(1);
    expect(pool.query.mock.calls[0][0]).toContain('INSERT INTO curtidas');
    expect(insertsNotificacao()).toHaveLength(0);
    expect(emitToFeed).not.toHaveBeenCalled();
  });
});

describe('publicacao_curtidas', () => {
  const token = gerarToken('user-1');

  beforeEach(() => {
    pool.query.mockReset();
    emitToFeed.mockReset();
  });

  function curtir() {
    return request(app).post('/v1/publicacoes/pub-1/curtir').set('Authorization', `Bearer ${token}`);
  }

  function descurtir() {
    return request(app).delete('/v1/publicacoes/pub-1/curtir').set('Authorization', `Bearer ${token}`);
  }

  it('curtida nova emite o total (contador lido + 1) com quem curtiu', async () => {
    pool.query
      .mockResolvedValueOnce({ rows: [{ autor_id: 'outro-user', curtidas_count: 3, nova: true }] })
      .mockResolvedValueOnce({ rows: [] });

    await curtir();

    expect(pool.query.mock.calls[0][0]).toContain('p.curtidas_count');
    expect(emitToFeed).toHaveBeenCalledTimes(1);
    expect(emitToFeed).toHaveBeenCalledWith('publicacao_curtidas', {
      publicacaoId: 'pub-1',
      curtidasCount: 4,
      porId: 'user-1',
    });
  });

  it('falha no emit da curtida só loga: mantém o 201 e a notificação', async () => {
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});
    pool.query
      .mockResolvedValueOnce({ rows: [{ autor_id: 'outro-user', curtidas_count: 3, nova: true }] })
      .mockResolvedValueOnce({ rows: [] });
    emitToFeed.mockImplementation(() => {
      throw new Error('socket caiu');
    });

    const res = await curtir();

    expect(res.status).toBe(201);
    expect(res.body).toEqual({ data: { curtido: true } });
    expect(insertsNotificacao()).toHaveLength(1);
    expect(erro).toHaveBeenCalledWith('[curtidas] erro ao emitir publicacao_curtidas:', expect.any(Error));
    erro.mockRestore();
  });

  it('descurtida que removeu emite o total (contador lido - 1)', async () => {
    pool.query.mockResolvedValueOnce({ rows: [{ curtidas_count: 4, removida: true }] });

    await descurtir();

    expect(pool.query.mock.calls[0][0]).toContain('p.curtidas_count');
    expect(emitToFeed).toHaveBeenCalledWith('publicacao_curtidas', {
      publicacaoId: 'pub-1',
      curtidasCount: 3,
      porId: 'user-1',
    });
  });

  it('descurtida nunca emite contador negativo', async () => {
    pool.query.mockResolvedValueOnce({ rows: [{ curtidas_count: 0, removida: true }] });

    await descurtir();

    expect(emitToFeed).toHaveBeenCalledWith('publicacao_curtidas', expect.objectContaining({ curtidasCount: 0 }));
  });

  it('descurtir o que não estava curtido não emite', async () => {
    pool.query.mockResolvedValueOnce({ rows: [{ curtidas_count: 4, removida: false }] });

    const res = await descurtir();

    expect(res.status).toBe(200);
    expect(emitToFeed).not.toHaveBeenCalled();
  });

  it('descurtir publicação inexistente não emite', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });

    const res = await descurtir();

    expect(res.status).toBe(200);
    expect(emitToFeed).not.toHaveBeenCalled();
  });

  it('falha no emit da descurtida só loga e mantém o 200', async () => {
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});
    pool.query.mockResolvedValueOnce({ rows: [{ curtidas_count: 4, removida: true }] });
    emitToFeed.mockImplementation(() => {
      throw new Error('socket caiu');
    });

    const res = await descurtir();

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ data: { curtido: false } });
    expect(erro).toHaveBeenCalledWith('[curtidas] erro ao emitir publicacao_curtidas:', expect.any(Error));
    erro.mockRestore();
  });
});