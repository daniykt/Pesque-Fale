jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');

const USUARIOS = [
  { id: 'u1', nome: 'Ana Souza', username: 'ana_pesca', foto_perfil: null, bio: null },
  { id: 'u2', nome: 'Anapolis Pesca Clube', username: 'anaxpesca', foto_perfil: null, bio: null },
  { id: 'u3', nome: 'Bruno Lima', username: 'bruno', foto_perfil: null, bio: null },
  { id: 'u4', nome: 'Carla 100% Pesca', username: 'carla', foto_perfil: null, bio: null },
  { id: 'u5', nome: 'Diego', username: 'diego\\rio', foto_perfil: null, bio: null },
];

function likeParaRegex(padrao, escape) {
  let fonte = '';
  for (let i = 0; i < padrao.length; i++) {
    const c = padrao[i];
    if (c === escape) {
      i++;
      fonte += padrao[i].replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    } else if (c === '%') {
      fonte += '.*';
    } else if (c === '_') {
      fonte += '.';
    } else {
      fonte += c.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    }
  }
  return new RegExp(`^${fonte}$`, 's');
}

function bancoFalso(sql, valores) {
  const escape = (sql.match(/ESCAPE '(.)'/) || [null, '\\'])[1];
  const regex = likeParaRegex(valores[0].toLowerCase(), escape);
  const achados = USUARIOS.filter(
    u => regex.test(u.nome.toLowerCase()) || regex.test(u.username.toLowerCase())
  );
  if (sql.includes('COUNT(*)')) {
    return Promise.resolve({ rows: [{ count: String(achados.length) }] });
  }
  return Promise.resolve({ rows: achados.slice(valores[3], valores[3] + valores[2]) });
}

function buscar(termo) {
  return request(app).get('/v1/usuarios').query({ busca: termo });
}

describe('GET /v1/usuarios — busca com % e _', () => {
  beforeEach(() => {
    pool.query.mockReset();
    pool.query.mockImplementation(bancoFalso);
  });

  it('buscar "_" não traz todo mundo', async () => {
    const res = await buscar('_');

    expect(res.status).toBe(200);
    expect(res.body.data.map(u => u.id)).toEqual(['u1']);
    expect(res.body.meta.total).toBe(1);
  });

  it('buscar "%" não traz todo mundo', async () => {
    const res = await buscar('%');

    expect(res.status).toBe(200);
    expect(res.body.data.map(u => u.id)).toEqual(['u4']);
    expect(res.body.meta.total).toBe(1);
  });

  it('"ana_pesca" acha o username com _ e não o que só se parece', async () => {
    const res = await buscar('ana_pesca');

    expect(res.status).toBe(200);
    expect(res.body.data.map(u => u.username)).toEqual(['ana_pesca']);
  });

  it('a barra invertida é tratada como texto', async () => {
    const res = await buscar('o\\r');

    expect(res.status).toBe(200);
    expect(res.body.data.map(u => u.id)).toEqual(['u5']);
  });

  it('a contagem bate com a lista', async () => {
    for (const termo of ['_', '%', 'ana_pesca', 'pesca', 'an_']) {
      const res = await buscar(termo);

      expect(res.body.meta.total).toBe(res.body.data.length);
    }
  });

  it('lista e contagem usam o mesmo termo escapado com ESCAPE', async () => {
    await buscar('a_b%c');

    expect(pool.query).toHaveBeenCalledTimes(2);
    for (const [sql, valores] of pool.query.mock.calls) {
      expect(sql.match(/LIKE LOWER\(\$1\) ESCAPE '\\'/g)).toHaveLength(2);
      expect(valores[0]).toBe('%a\\_b\\%c%');
    }
  });
});
