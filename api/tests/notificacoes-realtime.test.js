process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));
jest.mock('../src/config/socket-emitter', () => ({
  init: jest.fn(),
  emitToUser: jest.fn(),
}));

const request = require('supertest');
const pool = require('../src/config/database');
const { emitToUser } = require('../src/config/socket-emitter');
const app = require('../src/app');
const { criarNotificacao } = require('../src/modules/notificacoes/notificacoes.helper');
const { gerarToken } = require('./helpers/token');

const token = gerarToken('user-a');

// Linha completa como a CTE do helper devolve (mesmas colunas do GET).
function linhaNotificacao(overrides = {}) {
  return {
    id: 'notif-1',
    para: 'user-b',
    de_id: 'user-a',
    de: 'Fulano',
    de_username: 'fulano',
    de_foto: 'https://cdn/foto.jpg',
    ja_sigo_de: false,
    de_volta: false,
    tipo: 'curtida',
    texto: null,
    post_id: 'pub-1',
    chat_id: null,
    lida: false,
    criado_em: '2026-10-27T12:00:00.000Z',
    ...overrides,
  };
}

// Roteia o pool.query pelo SQL, sem depender da ordem exata das chamadas.
// `linha` é o que a CTE do helper (INSERT + SELECT) devolve; `falharNotificacao`
// faz essa query rejeitar.
function mockBanco({ autorPublicacao = 'user-b', linha = linhaNotificacao(), falharNotificacao = false } = {}) {
  pool.query.mockImplementation(async (sql) => {
    if (sql.includes('INSERT INTO notificacoes')) {
      if (falharNotificacao) throw new Error('conexão caiu');
      return { rows: [linha] };
    }
    if (sql.includes('INSERT INTO curtidas')) {
      return { rows: [{ autor_id: autorPublicacao, nova: true }] };
    }
    if (sql.includes('SELECT id FROM usuarios')) return { rows: [{ id: 'user-b' }] };
    if (sql.includes('INSERT INTO usuario_seguidores')) return { rows: [{ seguidor_id: 'user-a' }] };
    if (sql.includes('SELECT COUNT(*) FROM usuario_seguidores')) return { rows: [{ count: '1' }] };
    if (sql.includes('INSERT INTO comentarios')) {
      return {
        rows: [{
          id: 'com-1',
          publicacao_id: 'pub-1',
          autor_id: 'user-a',
          texto: 'Belo peixe!',
          criado_em: '2026-10-27T12:00:00.000Z',
          autor_nome: 'Fulano',
          autor_username: 'fulano',
          autor_foto: null,
          publicacao_autor_id: autorPublicacao,
        }],
      };
    }
    return { rows: [] };
  });
}

function insertsNotificacao() {
  return pool.query.mock.calls.filter(([sql]) => sql.includes('INSERT INTO notificacoes'));
}

describe('nova_notificacao via criarNotificacao', () => {
  beforeEach(() => {
    pool.query.mockReset();
    emitToUser.mockReset();
  });

  it('follow emite nova_notificacao pro seguido com tipo seguindo', async () => {
    mockBanco({ linha: linhaNotificacao({ tipo: 'seguindo', post_id: null }) });

    const res = await request(app)
      .post('/v1/usuarios/user-b/seguir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(201);
    // O follow também emite seguidor_adicionado (coberto em seguidores-realtime).
    const notificacoes = emitToUser.mock.calls.filter(([, evento]) => evento === 'nova_notificacao');
    expect(notificacoes).toHaveLength(1);
    const [destino, , payload] = notificacoes[0];
    expect(destino).toBe('user-b');
    expect(payload.tipo).toBe('seguindo');
  });

  it('curtida emite nova_notificacao pro autor da publicação com tipo curtida', async () => {
    mockBanco({ linha: linhaNotificacao({ tipo: 'curtida' }) });

    const res = await request(app)
      .post('/v1/publicacoes/pub-1/curtir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(201);
    expect(emitToUser).toHaveBeenCalledTimes(1);
    const [destino, evento, payload] = emitToUser.mock.calls[0];
    expect(destino).toBe('user-b');
    expect(evento).toBe('nova_notificacao');
    expect(payload.tipo).toBe('curtida');
    expect(payload.postId).toBe('pub-1');
  });

  it('comentário emite nova_notificacao pro autor da publicação com tipo comentario', async () => {
    mockBanco({ linha: linhaNotificacao({ tipo: 'comentario', texto: 'Belo peixe!' }) });

    const res = await request(app)
      .post('/v1/publicacoes/pub-1/comentarios')
      .set('Authorization', `Bearer ${token}`)
      .send({ texto: 'Belo peixe!' });

    expect(res.status).toBe(201);
    expect(emitToUser).toHaveBeenCalledTimes(1);
    const [destino, evento, payload] = emitToUser.mock.calls[0];
    expect(destino).toBe('user-b');
    expect(evento).toBe('nova_notificacao');
    expect(payload.tipo).toBe('comentario');
    expect(payload.texto).toBe('Belo peixe!');
  });

  it('curtir a própria publicação (para === deId) não insere nem emite', async () => {
    mockBanco({ autorPublicacao: 'user-a' });

    const res = await request(app)
      .post('/v1/publicacoes/pub-1/curtir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(201);
    expect(insertsNotificacao()).toHaveLength(0);
    expect(emitToUser).not.toHaveBeenCalled();
  });

  it('falha na query da notificação não quebra o caller nem emite', async () => {
    mockBanco({ falharNotificacao: true });
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});

    const res = await request(app)
      .post('/v1/publicacoes/pub-1/curtir')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(201);
    expect(res.body).toEqual({ data: { curtido: true } });
    expect(insertsNotificacao()).toHaveLength(1);
    expect(emitToUser).not.toHaveBeenCalled();
    expect(erro).toHaveBeenCalledWith('Erro ao criar notificação:', expect.any(Error));

    erro.mockRestore();
  });

  it('remetente inexistente (CTE sem linha) não emite', async () => {
    mockBanco();
    const base = pool.query.getMockImplementation();
    pool.query.mockImplementation(async (sql, params) => {
      if (sql.includes('INSERT INTO notificacoes')) return { rows: [] };
      return base(sql, params);
    });

    await criarNotificacao({ para: 'user-b', deId: 'user-a', tipo: 'curtida', postId: 'pub-1' });

    expect(emitToUser).not.toHaveBeenCalled();
  });

  it('cria a notificação com uma ida ao banco e os parâmetros na ordem da CTE', async () => {
    mockBanco();

    await criarNotificacao({
      para: 'user-b', deId: 'user-a', tipo: 'comentario', texto: 'Belo peixe!', postId: 'pub-1',
    });

    expect(pool.query.mock.calls.length).toBe(1);
    const [sql, params] = pool.query.mock.calls[0];
    expect(sql).toContain('INSERT INTO notificacoes');
    expect(params).toEqual(['user-b', 'user-a', 'comentario', 'Belo peixe!', 'pub-1', null, false]);
    expect(emitToUser).toHaveBeenCalledTimes(1);
  });

  it('para === deId não consulta o banco', async () => {
    await criarNotificacao({ para: 'user-a', deId: 'user-a', tipo: 'curtida', postId: 'pub-1' });

    expect(pool.query).not.toHaveBeenCalled();
    expect(emitToUser).not.toHaveBeenCalled();
  });

  it('payload tem shape idêntico ao item devolvido pelo GET /v1/notificacoes', async () => {
    const linha = linhaNotificacao({ ja_sigo_de: true, de_volta: true, tipo: 'seguindo', post_id: null });
    mockBanco({ linha });

    await criarNotificacao({ para: 'user-b', deId: 'user-a', tipo: 'seguindo', deVolta: true });
    const payload = emitToUser.mock.calls[0][2];

    // Mesma linha passando pelo _format do controller.
    pool.query.mockReset();
    pool.query
      .mockResolvedValueOnce({ rows: [linha] })
      .mockResolvedValueOnce({ rows: [{ count: '1' }] })
      .mockResolvedValueOnce({ rows: [{ count: '1' }] });
    const res = await request(app)
      .get('/v1/notificacoes')
      .set('Authorization', `Bearer ${gerarToken('user-b')}`);

    expect(res.status).toBe(200);
    expect(payload).toEqual(res.body.data[0]);
    expect(Object.keys(payload).sort()).toEqual([
      'chatId', 'criadoEm', 'de', 'deFoto', 'deId', 'deUsername', 'deVolta',
      'id', 'jaSigoDe', 'lida', 'para', 'postId', 'texto', 'tipo',
    ]);
  });
});
