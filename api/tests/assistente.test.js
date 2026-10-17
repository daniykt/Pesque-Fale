process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');
const { MAXIMO_POR_JANELA, consumir, limparLimites } = require('../src/modules/assistente/limite');

const token = gerarToken('user-1');

function respostaGemini(texto, status = 200) {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: async () => ({ candidates: [{ content: { parts: [{ text: texto }] } }] }),
  };
}

function perguntar(corpo) {
  return request(app)
    .post('/v1/assistente')
    .set('Authorization', `Bearer ${token}`)
    .send(corpo);
}

describe('POST /v1/assistente', () => {
  let fetchMock;

  beforeEach(() => {
    limparLimites();
    process.env.GEMINI_API_KEY = 'chave-teste';
    delete process.env.GEMINI_MODEL;
    fetchMock = jest.spyOn(global, 'fetch');
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('200 devolve a resposta da IA e a lista de ações', async () => {
    fetchMock.mockResolvedValueOnce(respostaGemini('Toque em Publicar no topo do Início.'));

    const res = await perguntar({ mensagem: 'Como publico uma pescaria?' });

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual({
      resposta: 'Toque em Publicar no topo do Início.',
      acoes: [],
    });
  });

  it('chama o Gemini com o modelo padrão, a chave no cabeçalho e as instruções', async () => {
    fetchMock.mockResolvedValueOnce(respostaGemini('Olá!'));

    await perguntar({ mensagem: 'Oi', tela: 'inicio' });

    const [url, opcoes] = fetchMock.mock.calls[0];
    const corpo = JSON.parse(opcoes.body);
    expect(url).toContain('/gemini-3.8-flash:generateContent');
    expect(opcoes.headers['x-goog-api-key']).toBe('chave-teste');
    expect(corpo.systemInstruction.parts[0].text).toContain('Pesque & Fale');
    expect(corpo.systemInstruction.parts[0].text).toContain('inicio');
    expect(corpo.contents).toEqual([{ role: 'user', parts: [{ text: 'Oi' }] }]);
  });

  it('usa o modelo definido em GEMINI_MODEL', async () => {
    process.env.GEMINI_MODEL = 'outro-modelo';
    fetchMock.mockResolvedValueOnce(respostaGemini('Olá!'));

    await perguntar({ mensagem: 'Oi' });

    expect(fetchMock.mock.calls[0][0]).toContain('/outro-modelo:generateContent');
  });

  it('envia só as 6 últimas mensagens do histórico, com os papéis convertidos', async () => {
    fetchMock.mockResolvedValueOnce(respostaGemini('Certo.'));
    const historico = Array.from({ length: 8 }, (_, i) => ({
      papel: i % 2 === 0 ? 'usuario' : 'assistente',
      texto: `mensagem ${i}`,
    }));

    await perguntar({ mensagem: 'E agora?', historico });

    const { contents } = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(contents).toHaveLength(7);
    expect(contents[0]).toEqual({ role: 'user', parts: [{ text: 'mensagem 2' }] });
    expect(contents[1].role).toBe('model');
    expect(contents[6]).toEqual({ role: 'user', parts: [{ text: 'E agora?' }] });
  });

  it('401 sem token', async () => {
    const res = await request(app).post('/v1/assistente').send({ mensagem: 'Oi' });
    expect(res.status).toBe(401);
  });

  it('400 com mensagem vazia', async () => {
    const res = await perguntar({ mensagem: '   ' });
    expect(res.status).toBe(400);
    expect(res.body.error).toBe('VALIDATION_ERROR');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('400 com mensagem acima de 500 caracteres', async () => {
    const res = await perguntar({ mensagem: 'a'.repeat(501) });
    expect(res.status).toBe(400);
    expect(res.body.details[0].campo).toBe('mensagem');
  });

  it('400 com histórico em formato inválido', async () => {
    const res = await perguntar({ mensagem: 'Oi', historico: [{ papel: 'robo', texto: 'x' }] });
    expect(res.status).toBe(400);
    expect(res.body.details[0].campo).toBe('historico');
  });

  it('503 sem GEMINI_API_KEY, sem chamar a IA', async () => {
    delete process.env.GEMINI_API_KEY;

    const res = await perguntar({ mensagem: 'Oi' });

    expect(res.status).toBe(503);
    expect(res.body.error).toBe('ASSISTENTE_INDISPONIVEL');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('503 quando o Gemini atinge o limite do plano', async () => {
    fetchMock.mockResolvedValueOnce(respostaGemini('', 429));

    const res = await perguntar({ mensagem: 'Oi' });

    expect(res.status).toBe(503);
    expect(res.body.error).toBe('ASSISTENTE_INDISPONIVEL');
  });

  it('503 quando o Gemini responde com erro', async () => {
    fetchMock.mockResolvedValueOnce(respostaGemini('', 500));
    const res = await perguntar({ mensagem: 'Oi' });
    expect(res.status).toBe(503);
  });

  it('503 quando a conexão com a IA falha', async () => {
    fetchMock.mockRejectedValueOnce(new Error('rede fora'));
    const res = await perguntar({ mensagem: 'Oi' });
    expect(res.status).toBe(503);
  });

  it('503 quando a IA demora demais', async () => {
    const erro = new Error('abortado');
    erro.name = 'AbortError';
    fetchMock.mockRejectedValueOnce(erro);

    const res = await perguntar({ mensagem: 'Oi' });

    expect(res.status).toBe(503);
  });

  it('503 quando a IA devolve resposta vazia', async () => {
    fetchMock.mockResolvedValueOnce(respostaGemini('   '));
    const res = await perguntar({ mensagem: 'Oi' });
    expect(res.status).toBe(503);
  });

  it('429 quando o usuário passa do limite de perguntas', async () => {
    for (let i = 0; i < MAXIMO_POR_JANELA; i++) consumir('user-1');

    const res = await perguntar({ mensagem: 'Oi' });

    expect(res.status).toBe(429);
    expect(res.body.error).toBe('LIMITE_ASSISTENTE');
    expect(fetchMock).not.toHaveBeenCalled();
  });
});

describe('limite de perguntas do assistente', () => {
  beforeEach(() => limparLimites());

  it('libera de novo depois de uma hora', () => {
    const inicio = 1_000_000;
    for (let i = 0; i < MAXIMO_POR_JANELA; i++) consumir('user-2', inicio);

    expect(consumir('user-2', inicio + 1000)).toBe(false);
    expect(consumir('user-2', inicio + 60 * 60 * 1000)).toBe(true);
  });

  it('conta cada usuário separadamente', () => {
    for (let i = 0; i < MAXIMO_POR_JANELA; i++) consumir('user-3');

    expect(consumir('user-3')).toBe(false);
    expect(consumir('user-4')).toBe(true);
  });
});