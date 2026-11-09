process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));
jest.mock('../src/config/socket-emitter', () => ({
  init: jest.fn(),
  emitToUser: jest.fn(),
  emitToFeed: jest.fn(),
}));

const request = require('supertest');
const pool = require('../src/config/database');
const { emitToUser, emitToFeed } = require('../src/config/socket-emitter');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const token = gerarToken('autor-1');
const criadoEm = '2026-10-27T12:00:00.000Z';

// Roteia o pool.query pelo SQL. `seguidores` é o que o SELECT do pivot
// devolve; `falharSeguidores` simula erro depois do INSERT já ter dado certo.
// `autorDaPublicacao` é o dono no SELECT do deletar (null = não existe);
// `falharDelete` simula erro no DELETE.
function mockBanco({
  seguidores = [],
  falharSeguidores = false,
  autorDaPublicacao = 'autor-1',
  falharDelete = false,
} = {}) {
  pool.query.mockImplementation(async (sql) => {
    if (sql.includes('SELECT autor_id FROM publicacoes')) {
      return { rows: autorDaPublicacao ? [{ autor_id: autorDaPublicacao }] : [] };
    }
    if (sql.includes('DELETE FROM publicacoes')) {
      if (falharDelete) throw new Error('conexão caiu');
      return { rows: [], rowCount: 1 };
    }
    if (sql.includes('INSERT INTO publicacoes')) {
      return {
        rows: [{
          id: 'pub-1',
          autor_id: 'autor-1',
          ponto_id: null,
          descricao: 'Peguei um tucunaré',
          imagem_url: null,
          local_texto: null,
          avaliacao_nota: null,
          tags: [],
          curtidas_count: 0,
          comentarios_count: 0,
          criado_em: criadoEm,
          atualizado_em: criadoEm,
        }],
      };
    }
    if (sql.includes('FROM usuario_seguidores')) {
      if (falharSeguidores) throw new Error('conexão caiu');
      return { rows: seguidores.map((id) => ({ seguidor_id: id })) };
    }
    return { rows: [] };
  });
}

function publicar() {
  return request(app)
    .post('/v1/publicacoes')
    .set('Authorization', `Bearer ${token}`)
    .send({ descricao: 'Peguei um tucunaré' });
}

describe('nova_publicacao_feed', () => {
  beforeEach(() => {
    pool.query.mockReset();
    emitToUser.mockReset();
    emitToFeed.mockReset();
  });

  it('emite pra cada seguidor do autor', async () => {
    mockBanco({ seguidores: ['seg-1', 'seg-2', 'seg-3'] });

    const res = await publicar();

    expect(res.status).toBe(201);
    expect(emitToUser).toHaveBeenCalledTimes(3);
    expect(emitToUser.mock.calls.map(([id]) => id)).toEqual(['seg-1', 'seg-2', 'seg-3']);
    for (const [, evento] of emitToUser.mock.calls) {
      expect(evento).toBe('nova_publicacao_feed');
    }

    const selects = pool.query.mock.calls.filter(([sql]) => sql.includes('FROM usuario_seguidores'));
    expect(selects).toHaveLength(1);
    expect(selects[0][0]).toMatch(/WHERE seguido_id = \$1/);
    expect(selects[0][1]).toEqual(['autor-1']);
  });

  it('autor sem seguidores não emite nada', async () => {
    mockBanco({ seguidores: [] });

    const res = await publicar();

    expect(res.status).toBe(201);
    expect(emitToUser).not.toHaveBeenCalled();
  });

  it('payload em camelCase com publicacaoId, autorId e timestamp', async () => {
    mockBanco({ seguidores: ['seg-1'] });

    await publicar();

    expect(emitToUser).toHaveBeenCalledWith('seg-1', 'nova_publicacao_feed', {
      publicacaoId: 'pub-1',
      autorId: 'autor-1',
      timestamp: criadoEm,
    });
  });

  it('erro na query de seguidores não quebra o response 201', async () => {
    mockBanco({ falharSeguidores: true });
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});

    const res = await publicar();

    expect(res.status).toBe(201);
    expect(res.body.data.id).toBe('pub-1');
    expect(emitToUser).not.toHaveBeenCalled();
    expect(erro).toHaveBeenCalledWith(
      '[publicacoes] erro ao emitir nova_publicacao_feed:',
      expect.any(Error)
    );

    erro.mockRestore();
  });

  it('autor não recebe o próprio emit', async () => {
    mockBanco({ seguidores: ['seg-1', 'seg-2'] });

    await publicar();

    expect(emitToUser).toHaveBeenCalledTimes(2);
    expect(emitToUser.mock.calls.map(([id]) => id)).not.toContain('autor-1');
  });
});

describe('publicacao_criada', () => {
  beforeEach(() => {
    pool.query.mockReset();
    emitToUser.mockReset();
    emitToFeed.mockReset();
  });

  it('emite para o feed com publicacaoId, autorId e timestamp', async () => {
    mockBanco({ seguidores: ['seg-1'] });

    const res = await publicar();

    expect(res.status).toBe(201);
    expect(emitToFeed).toHaveBeenCalledTimes(1);
    expect(emitToFeed).toHaveBeenCalledWith('publicacao_criada', {
      publicacaoId: 'pub-1',
      autorId: 'autor-1',
      timestamp: criadoEm,
    });
  });

  it('continua emitindo o nova_publicacao_feed para os seguidores', async () => {
    mockBanco({ seguidores: ['seg-1', 'seg-2'] });

    await publicar();

    expect(emitToFeed).toHaveBeenCalledWith('publicacao_criada', expect.any(Object));
    expect(emitToUser.mock.calls.map(([id, evento]) => [id, evento])).toEqual([
      ['seg-1', 'nova_publicacao_feed'],
      ['seg-2', 'nova_publicacao_feed'],
    ]);
  });

  it('emite mesmo para autor sem seguidores e mesmo se a query de seguidores falhar', async () => {
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});
    mockBanco({ falharSeguidores: true });

    const res = await publicar();

    expect(res.status).toBe(201);
    expect(emitToFeed).toHaveBeenCalledWith('publicacao_criada', expect.any(Object));
    erro.mockRestore();
  });

  it('falha no emit do feed só loga: mantém o 201 e o emit dos seguidores', async () => {
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});
    mockBanco({ seguidores: ['seg-1'] });
    emitToFeed.mockImplementation(() => {
      throw new Error('socket caiu');
    });

    const res = await publicar();

    expect(res.status).toBe(201);
    expect(res.body.data.id).toBe('pub-1');
    expect(emitToUser).toHaveBeenCalledWith('seg-1', 'nova_publicacao_feed', expect.any(Object));
    expect(erro).toHaveBeenCalledWith(
      '[publicacoes] erro ao emitir publicacao_criada:',
      expect.any(Error)
    );
    erro.mockRestore();
  });

  it('INSERT que falha não emite nada', async () => {
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});
    pool.query.mockRejectedValue(new Error('banco fora'));

    const res = await publicar();

    expect(res.status).toBe(500);
    expect(emitToFeed).not.toHaveBeenCalled();
    erro.mockRestore();
  });
});

describe('publicacao_removida', () => {
  function excluir(id = 'pub-1') {
    return request(app)
      .delete(`/v1/publicacoes/${id}`)
      .set('Authorization', `Bearer ${token}`);
  }

  beforeEach(() => {
    pool.query.mockReset();
    emitToFeed.mockReset();
  });

  it('emite para o feed depois do DELETE, com publicacaoId e autorId', async () => {
    mockBanco();

    const res = await excluir();

    expect(res.status).toBe(204);
    expect(emitToFeed).toHaveBeenCalledTimes(1);
    expect(emitToFeed).toHaveBeenCalledWith('publicacao_removida', {
      publicacaoId: 'pub-1',
      autorId: 'autor-1',
    });
    const indiceDelete = pool.query.mock.calls.findIndex(([sql]) => sql.includes('DELETE FROM publicacoes'));
    expect(indiceDelete).toBeGreaterThanOrEqual(0);
    expect(pool.query.mock.invocationCallOrder[indiceDelete]).toBeLessThan(
      emitToFeed.mock.invocationCallOrder[0]
    );
  });

  it('publicação inexistente (404) não emite', async () => {
    mockBanco({ autorDaPublicacao: null });

    const res = await excluir();

    expect(res.status).toBe(404);
    expect(emitToFeed).not.toHaveBeenCalled();
  });

  it('publicação de outra pessoa (403) não emite', async () => {
    mockBanco({ autorDaPublicacao: 'outra-pessoa' });

    const res = await excluir();

    expect(res.status).toBe(403);
    expect(emitToFeed).not.toHaveBeenCalled();
  });

  it('erro no DELETE (500) não emite', async () => {
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});
    mockBanco({ falharDelete: true });

    const res = await excluir();

    expect(res.status).toBe(500);
    expect(emitToFeed).not.toHaveBeenCalled();
    erro.mockRestore();
  });

  it('falha no emit só loga e mantém o 204', async () => {
    const erro = jest.spyOn(console, 'error').mockImplementation(() => {});
    mockBanco();
    emitToFeed.mockImplementation(() => {
      throw new Error('socket caiu');
    });

    const res = await excluir();

    expect(res.status).toBe(204);
    expect(erro).toHaveBeenCalledWith(
      '[publicacoes] erro ao emitir publicacao_removida:',
      expect.any(Error)
    );
    erro.mockRestore();
  });
});
