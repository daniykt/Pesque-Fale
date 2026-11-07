jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const token = gerarToken('user-1');

const linhaEvento = (extra = {}) => ({
  id: 'ev-1',
  titulo: 'Torneio',
  descricao: null,
  ponto_id: null,
  organizador_id: 'user-1',
  data_inicio: new Date('2026-08-15T08:00:00Z'),
  data_fim: null,
  imagem_url: null,
  local_texto: null,
  criado_em: new Date('2026-08-01T00:00:00Z'),
  atualizado_em: new Date('2026-08-01T00:00:00Z'),
  ...extra,
});

function criar(body) {
  return request(app).post('/v1/eventos').set('Authorization', `Bearer ${token}`).send(body);
}

function atualizar(body) {
  return request(app).patch('/v1/eventos/ev-1').set('Authorization', `Bearer ${token}`).send(body);
}

function salvo(dataInicio, dataFim = null) {
  pool.query.mockResolvedValueOnce({
    rows: [{ organizador_id: 'user-1', data_inicio: new Date(dataInicio), data_fim: dataFim && new Date(dataFim) }],
  });
}

const valido = { titulo: 'Torneio de Matão', dataInicio: '2026-08-15T08:00:00Z' };

function camposComErro(res) {
  return res.body.details.map(d => d.campo);
}

describe('eventos', () => {
  let consoleErrorSpy;

  beforeEach(() => {
    pool.query.mockReset();
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    consoleErrorSpy.mockRestore();
  });

  describe('GET /v1/eventos', () => {
    function listar(query) {
      pool.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [{ count: '0' }] });
      return request(app).get('/v1/eventos').query(query);
    }

    it('com futuros=true, ordena do mais próximo para o mais distante', async () => {
      const res = await listar({ futuros: 'true' });

      expect(res.status).toBe(200);
      const [sqlLista] = pool.query.mock.calls[0];
      expect(sqlLista).toMatch(/ORDER BY e\.data_inicio ASC/);
    });

    it('com futuros=true, inclui eventos em andamento na lista e no COUNT', async () => {
      await listar({ futuros: 'true' });

      const [sqlLista] = pool.query.mock.calls[0];
      const [sqlCount] = pool.query.mock.calls[1];
      for (const sql of [sqlLista, sqlCount]) {
        expect(sql).toContain('WHERE COALESCE(data_fim, data_inicio) >= NOW()');
        expect(sql).not.toMatch(/WHERE data_inicio >= NOW\(\)/);
      }
      expect(sqlCount).toContain('COUNT(*)');
    });

    it('sem futuros, lista todos do mais recente para o mais antigo', async () => {
      await listar({});

      const [sqlLista] = pool.query.mock.calls[0];
      const [sqlCount] = pool.query.mock.calls[1];
      expect(sqlLista).toMatch(/ORDER BY e\.data_inicio DESC/);
      expect(sqlLista).not.toContain('WHERE');
      expect(sqlCount).not.toContain('WHERE');
    });
  });

  describe('POST /v1/eventos — validação', () => {
    it('aceita um evento válido, com e sem fim e sem segundos', async () => {
      pool.query.mockResolvedValue({ rows: [linhaEvento()] });

      const semFim = await criar(valido);
      const comFim = await criar({ ...valido, dataFim: '2026-08-15T14:30:00.000Z' });
      const mesmoHorario = await criar({ ...valido, dataFim: valido.dataInicio });
      const semSegundos = await criar({ ...valido, dataInicio: '2026-08-15T08:00Z' });

      expect(semFim.status).toBe(201);
      expect(comFim.status).toBe(201);
      expect(mesmoHorario.status).toBe(201);
      expect(semSegundos.status).toBe(201);
    });

    it('grava as datas em UTC, convertendo o offset', async () => {
      pool.query.mockResolvedValueOnce({ rows: [linhaEvento()] });

      const res = await criar({
        ...valido,
        dataInicio: '2026-11-20T08:00:00-03:00',
        dataFim: '2026-11-20T23:30:00.250-03:00',
      });

      expect(res.status).toBe(201);
      const [, valores] = pool.query.mock.calls[0];
      expect(valores[4]).toBe('2026-11-20T11:00:00.000Z');
      expect(valores[5]).toBe('2026-11-21T02:30:00.250Z');
    });

    it('grava em UTC também com Z e com offset positivo', async () => {
      pool.query.mockResolvedValue({ rows: [linhaEvento()] });

      await criar({ ...valido, dataInicio: '2026-11-20T11:00:00Z' });
      await criar({ ...valido, dataInicio: '2026-11-20T14:30:00+03:30' });

      expect(pool.query.mock.calls[0][1][4]).toBe('2026-11-20T11:00:00.000Z');
      expect(pool.query.mock.calls[1][1][4]).toBe('2026-11-20T11:00:00.000Z');
      expect(pool.query.mock.calls[0][1][5]).toBeNull();
    });

    it('compara início e fim já em UTC', async () => {
      const res = await criar({
        ...valido,
        dataInicio: '2026-11-20T08:00:00-03:00',
        dataFim: '2026-11-20T10:00:00Z',
      });

      expect(res.status).toBe(400);
      expect(res.body.details).toEqual([
        { campo: 'dataFim', mensagem: 'A data de fim deve ser igual ou posterior à data de início.' },
      ]);
    });

    it('recusa data sem fuso, no início e no fim', async () => {
      const semFusoNoInicio = await criar({ ...valido, dataInicio: '2026-11-20T11:00:00' });
      const semFusoNoFim = await criar({ ...valido, dataFim: '2026-11-20T11:00:00' });

      expect(semFusoNoInicio.status).toBe(400);
      expect(semFusoNoInicio.body.details).toEqual([
        { campo: 'dataInicio', mensagem: 'Data de início inválida. Informe o fuso (ex.: 2026-11-20T11:00:00Z).' },
      ]);
      expect(semFusoNoFim.status).toBe(400);
      expect(semFusoNoFim.body.details).toEqual([
        { campo: 'dataFim', mensagem: 'Data de fim inválida. Informe o fuso (ex.: 2026-11-20T11:00:00Z).' },
      ]);
      expect(pool.query).not.toHaveBeenCalled();
    });

    it.each([
      ['ausente', undefined],
      ['com 1 caractere', 'A'],
      ['só com espaços', '   '],
      ['com 201 caracteres', 'a'.repeat(201)],
      ['que não é texto', 123],
    ])('recusa título %s', async (_, titulo) => {
      const res = await criar({ ...valido, titulo });

      expect(res.status).toBe(400);
      expect(res.body.error).toBe('VALIDATION_ERROR');
      expect(res.body.details).toEqual([
        { campo: 'titulo', mensagem: 'Título deve ter entre 2 e 200 caracteres.' },
      ]);
      expect(pool.query).not.toHaveBeenCalled();
    });

    it('aceita título com 2 e com 200 caracteres', async () => {
      pool.query.mockResolvedValue({ rows: [linhaEvento()] });

      expect((await criar({ ...valido, titulo: 'ab' })).status).toBe(201);
      expect((await criar({ ...valido, titulo: 'a'.repeat(200) })).status).toBe(201);
    });

    it('recusa localTexto com mais de 150 caracteres e aceita 150', async () => {
      pool.query.mockResolvedValue({ rows: [linhaEvento()] });

      const longo = await criar({ ...valido, localTexto: 'a'.repeat(151) });
      const limite = await criar({ ...valido, localTexto: 'a'.repeat(150) });

      expect(longo.status).toBe(400);
      expect(longo.body.details).toEqual([
        { campo: 'localTexto', mensagem: 'Local deve ter no máximo 150 caracteres.' },
      ]);
      expect(limite.status).toBe(201);
    });

    it('recusa sem dataInicio', async () => {
      const res = await criar({ titulo: 'Torneio' });

      expect(res.status).toBe(400);
      expect(res.body.details).toEqual([
        { campo: 'dataInicio', mensagem: 'Data de início é obrigatória.' },
      ]);
    });

    it.each([
      ['texto qualquer', 'amanhã'],
      ['número solto', '1'],
      ['dia que não existe', '2026-02-30T10:00:00Z'],
      ['mês que não existe', '2026-13-01T10:00:00Z'],
      ['hora que não existe', '2026-08-15T24:00:00Z'],
      ['formato brasileiro', '15/08/2026 08:00'],
      ['fuso que não existe', '2026-08-15T08:00:00+15:00'],
      ['fuso sem os dois pontos', '2026-08-15T08:00:00-0300'],
      ['número', 1786780800000],
    ])('recusa dataInicio inválida: %s', async (_, dataInicio) => {
      const res = await criar({ ...valido, dataInicio });

      expect(res.status).toBe(400);
      expect(res.body.details).toEqual([
        {
          campo: 'dataInicio',
          mensagem: 'Data de início inválida. Use o formato ISO-8601 com fuso (ex.: 2026-11-20T11:00:00Z).',
        },
      ]);
      expect(pool.query).not.toHaveBeenCalled();
    });

    it('recusa dataFim inválida', async () => {
      const res = await criar({ ...valido, dataFim: '2026-02-30T10:00:00Z' });

      expect(res.status).toBe(400);
      expect(camposComErro(res)).toEqual(['dataFim']);
    });

    it('recusa dataFim antes da dataInicio', async () => {
      const res = await criar({ ...valido, dataFim: '2026-08-15T07:59:00Z' });

      expect(res.status).toBe(400);
      expect(res.body.details).toEqual([
        { campo: 'dataFim', mensagem: 'A data de fim deve ser igual ou posterior à data de início.' },
      ]);
      expect(pool.query).not.toHaveBeenCalled();
    });

    it('devolve todos os erros de uma vez', async () => {
      const res = await criar({ titulo: 'A', localTexto: 'a'.repeat(151), dataInicio: 'x' });

      expect(camposComErro(res)).toEqual(['titulo', 'localTexto', 'dataInicio']);
    });
  });

  describe('PATCH /v1/eventos/:id — validação', () => {
    it('busca as datas salvas no mesmo SELECT de permissão', async () => {
      salvo('2026-08-15T08:00:00Z');
      pool.query.mockResolvedValueOnce({ rows: [linhaEvento()] });

      await atualizar({ titulo: 'Novo título' });

      expect(pool.query).toHaveBeenCalledTimes(2);
      const [sqlPermissao] = pool.query.mock.calls[0];
      expect(sqlPermissao).toBe('SELECT organizador_id, data_inicio, data_fim FROM eventos WHERE id = $1');
    });

    it('só dataFim: recusa se for antes da dataInicio salva', async () => {
      salvo('2026-08-15T08:00:00Z');

      const res = await atualizar({ dataFim: '2026-08-15T07:00:00Z' });

      expect(res.status).toBe(400);
      expect(camposComErro(res)).toEqual(['dataFim']);
      expect(pool.query).toHaveBeenCalledTimes(1);
    });

    it('só dataFim: aceita se for depois da dataInicio salva', async () => {
      salvo('2026-08-15T08:00:00Z');
      pool.query.mockResolvedValueOnce({ rows: [linhaEvento()] });

      const res = await atualizar({ dataFim: '2026-08-15T12:00:00Z' });

      expect(res.status).toBe(200);
    });

    it('só dataInicio: recusa se for depois da dataFim salva', async () => {
      salvo('2026-08-15T08:00:00Z', '2026-08-15T12:00:00Z');

      const res = await atualizar({ dataInicio: '2026-08-16T08:00:00Z' });

      expect(res.status).toBe(400);
      expect(camposComErro(res)).toEqual(['dataFim']);
      expect(pool.query).toHaveBeenCalledTimes(1);
    });

    it('só dataInicio: aceita quando não há dataFim salva', async () => {
      salvo('2026-08-15T08:00:00Z');
      pool.query.mockResolvedValueOnce({ rows: [linhaEvento()] });

      const res = await atualizar({ dataInicio: '2026-09-01T08:00:00Z' });

      expect(res.status).toBe(200);
    });

    it('as duas datas: compara entre si, não com o salvo', async () => {
      salvo('2026-08-15T08:00:00Z', '2026-08-15T12:00:00Z');
      pool.query.mockResolvedValueOnce({ rows: [linhaEvento()] });

      const res = await atualizar({ dataInicio: '2026-09-01T08:00:00Z', dataFim: '2026-09-01T10:00:00Z' });

      expect(res.status).toBe(200);
    });

    it('grava no UPDATE as datas convertidas para UTC', async () => {
      salvo('2026-08-15T08:00:00Z');
      pool.query.mockResolvedValueOnce({ rows: [linhaEvento()] });

      const res = await atualizar({ dataInicio: '2026-11-20T08:00:00-03:00', dataFim: '2026-11-20T12:00:00-03:00' });

      expect(res.status).toBe(200);
      const [sql, valores] = pool.query.mock.calls[1];
      expect(sql).toContain('data_inicio = $1');
      expect(sql).toContain('data_fim = $2');
      expect(valores.slice(0, 2)).toEqual(['2026-11-20T11:00:00.000Z', '2026-11-20T15:00:00.000Z']);
    });

    it('só dataFim com offset: compara em UTC com a dataInicio salva', async () => {
      salvo('2026-11-20T11:00:00Z');

      const res = await atualizar({ dataFim: '2026-11-20T07:30:00-03:00' });

      expect(res.status).toBe(400);
      expect(camposComErro(res)).toEqual(['dataFim']);
    });

    it('recusa dataFim sem fuso no atualizar', async () => {
      salvo('2026-08-15T08:00:00Z');

      const res = await atualizar({ dataFim: '2026-08-15T12:00:00' });

      expect(res.status).toBe(400);
      expect(res.body.details).toEqual([
        { campo: 'dataFim', mensagem: 'Data de fim inválida. Informe o fuso (ex.: 2026-11-20T11:00:00Z).' },
      ]);
      expect(pool.query).toHaveBeenCalledTimes(1);
    });

    it('dataFim null remove o fim sem comparar', async () => {
      salvo('2026-08-15T08:00:00Z', '2026-08-15T12:00:00Z');
      pool.query.mockResolvedValueOnce({ rows: [linhaEvento()] });

      const res = await atualizar({ dataFim: null });

      expect(res.status).toBe(200);
    });

    it.each([
      ['título curto', { titulo: 'A' }, 'titulo'],
      ['local longo', { localTexto: 'a'.repeat(151) }, 'localTexto'],
      ['dataInicio inválida', { dataInicio: '2026-02-30T10:00:00Z' }, 'dataInicio'],
      ['dataInicio null', { dataInicio: null }, 'dataInicio'],
      ['dataFim inválida', { dataFim: 'depois' }, 'dataFim'],
    ])('recusa %s', async (_, body, campo) => {
      salvo('2026-08-15T08:00:00Z');

      const res = await atualizar(body);

      expect(res.status).toBe(400);
      expect(camposComErro(res)).toEqual([campo]);
      expect(pool.query).toHaveBeenCalledTimes(1);
    });

    it('não valida o título quando ele não vem', async () => {
      salvo('2026-08-15T08:00:00Z');
      pool.query.mockResolvedValueOnce({ rows: [linhaEvento()] });

      const res = await atualizar({ descricao: 'Nova descrição' });

      expect(res.status).toBe(200);
    });

    it('outro usuário continua recebendo 403 antes da validação', async () => {
      pool.query.mockResolvedValueOnce({
        rows: [{ organizador_id: 'outra-pessoa', data_inicio: new Date(), data_fim: null }],
      });

      const res = await atualizar({ titulo: 'A' });

      expect(res.status).toBe(403);
    });
  });
});
