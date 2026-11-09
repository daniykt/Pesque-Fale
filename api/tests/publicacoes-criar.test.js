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
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const token = gerarToken('autor-1');
const criadoEm = '2026-11-05T12:00:00.000Z';

const linhaPublicacao = {
  id: 'pub-1',
  autor_id: 'autor-1',
  ponto_id: 'ponto-1',
  descricao: 'Peguei um tucunaré',
  imagem_url: 'https://res.cloudinary.com/demo/image/upload/post.jpg',
  local_texto: 'Rio das Pratas',
  avaliacao_nota: '4.5',
  tags: ['tucunaré'],
  curtidas_count: 0,
  comentarios_count: 0,
  criado_em: criadoEm,
  atualizado_em: criadoEm,
};

const colunasDoAutor = {
  autor_nome: 'Ana Pescadora',
  autor_username: 'ana_pesca',
  autor_foto: 'https://res.cloudinary.com/demo/image/upload/ana.jpg',
};

// Imita o banco: as colunas do autor só existem quando o SQL junta usuarios.
function mockBanco({ extrasDoUsuario = {} } = {}) {
  pool.query.mockImplementation(async (sql) => {
    if (sql.includes('INSERT INTO publicacoes')) {
      const autor = sql.includes('JOIN usuarios') ? { ...colunasDoAutor, ...extrasDoUsuario } : {};
      return { rows: [{ ...linhaPublicacao, ...autor }] };
    }
    return { rows: [] };
  });
}

function publicar() {
  return request(app)
    .post('/v1/publicacoes')
    .set('Authorization', `Bearer ${token}`)
    .send({
      descricao: 'Peguei um tucunaré',
      imagemUrl: 'https://res.cloudinary.com/demo/image/upload/post.jpg',
      localTexto: 'Rio das Pratas',
      avaliacaoNota: 4.5,
      pontoId: 'ponto-1',
      tags: ['tucunaré'],
    });
}

describe('POST /v1/publicacoes', () => {
  beforeEach(() => {
    pool.query.mockReset();
  });

  it('devolve a publicação com nome, username e foto do autor', async () => {
    mockBanco();

    const res = await publicar();

    expect(res.status).toBe(201);
    expect(res.body.data).toMatchObject({
      id: 'pub-1',
      autorId: 'autor-1',
      autorNome: 'Ana Pescadora',
      autorUsername: 'ana_pesca',
      autorFoto: 'https://res.cloudinary.com/demo/image/upload/ana.jpg',
      descricao: 'Peguei um tucunaré',
      avaliacaoNota: 4.5,
      jaCurtiu: false,
    });
  });

  it('insere com o autor do token e junta usuarios pelo autor_id, numa query só', async () => {
    mockBanco();

    await publicar();

    const inserts = pool.query.mock.calls.filter(([sql]) => sql.includes('INSERT INTO publicacoes'));
    expect(inserts).toHaveLength(1);
    const [sql, params] = inserts[0];
    expect(sql).toMatch(/JOIN usuarios u ON u\.id = nova\.autor_id/);
    expect(params[0]).toBe('autor-1');
    expect(params).toEqual([
      'autor-1',
      'ponto-1',
      'Peguei um tucunaré',
      'https://res.cloudinary.com/demo/image/upload/post.jpg',
      'Rio das Pratas',
      4.5,
      ['tucunaré'],
    ]);
  });

  it('não seleciona nem devolve senha_hash, firebase_uid ou email do autor', async () => {
    mockBanco({
      extrasDoUsuario: { senha_hash: 'hash', firebase_uid: 'fb-1', email: 'ana@teste.com' },
    });

    const res = await publicar();

    const [sql] = pool.query.mock.calls.find(([s]) => s.includes('INSERT INTO publicacoes'));
    expect(sql).not.toMatch(/u\.\*/);
    expect(sql).not.toMatch(/senha_hash|firebase_uid|u\.email/);
    const corpo = JSON.stringify(res.body);
    expect(corpo).not.toMatch(/senha|firebase|ana@teste\.com/);
  });
});
