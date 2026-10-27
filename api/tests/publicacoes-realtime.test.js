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
const { gerarToken } = require('./helpers/token');

const token = gerarToken('autor-1');
const criadoEm = '2026-10-27T12:00:00.000Z';

// Roteia o pool.query pelo SQL. `seguidores` é o que o SELECT do pivot
// devolve; `falharSeguidores` simula erro depois do INSERT já ter dado certo.
function mockBanco({ seguidores = [], falharSeguidores = false } = {}) {
  pool.query.mockImplementation(async (sql) => {
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
