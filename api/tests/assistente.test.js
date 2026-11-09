process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
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

function chamadaDeFerramenta(name, args) {
  return {
    ok: true,
    status: 200,
    json: async () => ({
      candidates: [{ content: { role: 'model', parts: [{ functionCall: { name, args } }] } }],
    }),
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
    delete process.env.GROQ_API_KEY;
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
    const nomes = corpo.tools[0].functionDeclarations.map((f) => f.name);
    expect(nomes).toEqual(['buscar_locais', 'sugerir_tela']);
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

  it('503 sem GEMINI_API_KEY e sem GROQ_API_KEY, sem chamar a IA', async () => {
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

describe('ferramentas do assistente', () => {
  let fetchMock;

  beforeEach(() => {
    limparLimites();
    pool.query.mockReset();
    process.env.GEMINI_API_KEY = 'chave-teste';
    delete process.env.GROQ_API_KEY;
    fetchMock = jest.spyOn(global, 'fetch');
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('buscar_locais consulta o banco e devolve botões para abrir os locais', async () => {
    pool.query.mockResolvedValueOnce({
      rows: [
        { id: 'ponto-1', nome: 'Lago Azul', tipo: 'lago', cidade: 'Matão', estado: 'SP', avg_nota: '4.5' },
      ],
    });
    fetchMock
      .mockResolvedValueOnce(chamadaDeFerramenta('buscar_locais', { busca: 'Lago Azul' }))
      .mockResolvedValueOnce(respostaGemini('O Lago Azul fica em Matão.'));

    const res = await perguntar({ mensagem: 'Onde fica o Lago Azul?' });

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual({
      resposta: 'O Lago Azul fica em Matão.',
      acoes: [{ tipo: 'abrir_local', pontoId: 'ponto-1', rotulo: 'Ver Lago Azul' }],
    });

    const [sql, valores] = pool.query.mock.calls[0];
    expect(sql).toContain('FROM pontos_de_pesca');
    expect(sql).toContain('LIMIT');
    expect(valores).toEqual(['%Lago Azul%', 5]);

    const segundaChamada = JSON.parse(fetchMock.mock.calls[1][1].body);
    const resultado = segundaChamada.contents.at(-1).parts[0].functionResponse;
    expect(resultado.name).toBe('buscar_locais');
    expect(resultado.response.locais[0]).toMatchObject({ nome: 'Lago Azul', nota: 4.5 });
    expect(segundaChamada.contents.at(-2).parts[0].functionCall.name).toBe('buscar_locais');
  });

  it('buscar_locais ignora tipo inválido e filtra por cidade', async () => {
    pool.query.mockResolvedValueOnce({ rows: [] });
    fetchMock
      .mockResolvedValueOnce(chamadaDeFerramenta('buscar_locais', { tipo: 'piscina', cidade: 'Matão' }))
      .mockResolvedValueOnce(respostaGemini('Ainda não há locais cadastrados em Matão.'));

    const res = await perguntar({ mensagem: 'Tem lugar pra pescar em Matão?' });

    expect(res.status).toBe(200);
    expect(res.body.data.acoes).toEqual([]);
    const [sql, valores] = pool.query.mock.calls[0];
    expect(sql).not.toContain('tipo =');
    expect(valores).toEqual(['Matão', 5]);
  });

  it('sugerir_tela devolve um botão para a tela pedida', async () => {
    fetchMock
      .mockResolvedValueOnce(chamadaDeFerramenta('sugerir_tela', { tela: 'nova_publicacao' }))
      .mockResolvedValueOnce(respostaGemini('Toque no botão abaixo e preencha a publicação.'));

    const res = await perguntar({ mensagem: 'Como publico uma pescaria?' });

    expect(res.status).toBe(200);
    expect(res.body.data.acoes).toEqual([
      { tipo: 'abrir_tela', tela: 'nova_publicacao', rotulo: 'Abrir tela de publicar' },
    ]);
  });

  it('sugerir_tela com tela inventada não gera botão', async () => {
    fetchMock
      .mockResolvedValueOnce(chamadaDeFerramenta('sugerir_tela', { tela: 'painel_admin' }))
      .mockResolvedValueOnce(respostaGemini('Essa tela não existe no app.'));

    const res = await perguntar({ mensagem: 'Abre o painel de admin' });

    expect(res.status).toBe(200);
    expect(res.body.data.acoes).toEqual([]);
    const resultado = JSON.parse(fetchMock.mock.calls[1][1].body).contents.at(-1).parts[0]
      .functionResponse.response;
    expect(resultado).toHaveProperty('erro');
  });

  it('erro no banco vira aviso para a IA, sem derrubar a resposta', async () => {
    pool.query.mockRejectedValueOnce(new Error('banco fora'));
    fetchMock
      .mockResolvedValueOnce(chamadaDeFerramenta('buscar_locais', { busca: 'Lago' }))
      .mockResolvedValueOnce(respostaGemini('Não consegui consultar os locais agora.'));

    const res = await perguntar({ mensagem: 'Onde fica o Lago Azul?' });

    expect(res.status).toBe(200);
    expect(res.body.data.acoes).toEqual([]);
  });

  it('503 se a IA continuar pedindo ferramentas sem concluir', async () => {
    fetchMock.mockResolvedValue(chamadaDeFerramenta('sugerir_tela', { tela: 'chat' }));

    const res = await perguntar({ mensagem: 'Oi' });

    expect(res.status).toBe(503);
    expect(fetchMock).toHaveBeenCalledTimes(3);
  });
});

function respostaGroq(texto, status = 200) {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: async () => ({ choices: [{ message: { role: 'assistant', content: texto } }] }),
  };
}

function chamadaDeFerramentaGroq(name, args) {
  return {
    ok: true,
    status: 200,
    json: async () => ({
      choices: [
        {
          message: {
            role: 'assistant',
            content: null,
            tool_calls: [
              { id: 'call-1', type: 'function', function: { name, arguments: JSON.stringify(args) } },
            ],
          },
        },
      ],
    }),
  };
}

describe('fallback para o Groq', () => {
  let fetchMock;

  beforeEach(() => {
    limparLimites();
    pool.query.mockReset();
    process.env.GEMINI_API_KEY = 'chave-teste';
    process.env.GROQ_API_KEY = 'chave-groq';
    delete process.env.GEMINI_MODEL;
    delete process.env.GROQ_MODEL;
    fetchMock = jest.spyOn(global, 'fetch');
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    delete process.env.GROQ_API_KEY;
    jest.restoreAllMocks();
  });

  it('usa o Groq quando o Gemini atinge o limite', async () => {
    fetchMock
      .mockResolvedValueOnce(respostaGemini('', 429))
      .mockResolvedValueOnce(respostaGroq('Toque em Publicar no Início.'));

    const res = await perguntar({ mensagem: 'Como publico?' });

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual({ resposta: 'Toque em Publicar no Início.', acoes: [] });

    const [url, opcoes] = fetchMock.mock.calls[1];
    const corpo = JSON.parse(opcoes.body);
    expect(url).toBe('https://api.groq.com/openai/v1/chat/completions');
    expect(opcoes.headers.Authorization).toBe('Bearer chave-groq');
    expect(corpo.model).toBe('openai/gpt-oss-120b');
    expect(corpo.messages[0].role).toBe('system');
    expect(corpo.messages[0].content).toContain('Pesque & Fale');
    expect(corpo.messages.at(-1)).toEqual({ role: 'user', content: 'Como publico?' });
    expect(corpo.tools.map((f) => f.function.name)).toEqual(['buscar_locais', 'sugerir_tela']);
  });

  it('usa o Groq quando o Gemini demora demais', async () => {
    const erro = new Error('abortado');
    erro.name = 'AbortError';
    fetchMock.mockRejectedValueOnce(erro).mockResolvedValueOnce(respostaGroq('Olá!'));

    const res = await perguntar({ mensagem: 'Oi' });

    expect(res.status).toBe(200);
    expect(res.body.data.resposta).toBe('Olá!');
  });

  it('não chama o Groq quando o Gemini responde', async () => {
    fetchMock.mockResolvedValueOnce(respostaGemini('Olá!'));

    const res = await perguntar({ mensagem: 'Oi' });

    expect(res.status).toBe(200);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('usa só o Groq quando não há GEMINI_API_KEY', async () => {
    delete process.env.GEMINI_API_KEY;
    fetchMock.mockResolvedValueOnce(respostaGroq('Olá!'));

    const res = await perguntar({ mensagem: 'Oi' });

    expect(res.status).toBe(200);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchMock.mock.calls[0][0]).toContain('api.groq.com');
  });

  it('usa o modelo definido em GROQ_MODEL e converte o histórico', async () => {
    process.env.GROQ_MODEL = 'outro-modelo-groq';
    fetchMock.mockResolvedValueOnce(respostaGemini('', 500)).mockResolvedValueOnce(respostaGroq('Certo.'));

    await perguntar({
      mensagem: 'E agora?',
      historico: [
        { papel: 'usuario', texto: 'Oi' },
        { papel: 'assistente', texto: 'Olá!' },
      ],
    });

    const corpo = JSON.parse(fetchMock.mock.calls[1][1].body);
    expect(corpo.model).toBe('outro-modelo-groq');
    expect(corpo.messages.slice(1)).toEqual([
      { role: 'user', content: 'Oi' },
      { role: 'assistant', content: 'Olá!' },
      { role: 'user', content: 'E agora?' },
    ]);
  });

  it('executa as ferramentas pelo Groq e devolve as ações', async () => {
    pool.query.mockResolvedValueOnce({
      rows: [
        { id: 'ponto-1', nome: 'Lago Azul', tipo: 'lago', cidade: 'Matão', estado: 'SP', avg_nota: '4.5' },
      ],
    });
    fetchMock
      .mockResolvedValueOnce(respostaGemini('', 429))
      .mockResolvedValueOnce(chamadaDeFerramentaGroq('buscar_locais', { busca: 'Lago Azul' }))
      .mockResolvedValueOnce(respostaGroq('O Lago Azul fica em Matão.'));

    const res = await perguntar({ mensagem: 'Onde fica o Lago Azul?' });

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual({
      resposta: 'O Lago Azul fica em Matão.',
      acoes: [{ tipo: 'abrir_local', pontoId: 'ponto-1', rotulo: 'Ver Lago Azul' }],
    });

    const mensagens = JSON.parse(fetchMock.mock.calls[2][1].body).messages;
    expect(mensagens.at(-2).tool_calls[0].function.name).toBe('buscar_locais');
    expect(mensagens.at(-1).role).toBe('tool');
    expect(mensagens.at(-1).tool_call_id).toBe('call-1');
    expect(JSON.parse(mensagens.at(-1).content).locais[0]).toMatchObject({ nome: 'Lago Azul' });
  });

  it('não repete as ações da tentativa do Gemini que falhou', async () => {
    fetchMock
      .mockResolvedValueOnce(chamadaDeFerramenta('sugerir_tela', { tela: 'chat' }))
      .mockResolvedValueOnce(respostaGemini('', 500))
      .mockResolvedValueOnce(respostaGroq('Pronto.'));

    const res = await perguntar({ mensagem: 'Oi' });

    expect(res.status).toBe(200);
    expect(res.body.data.acoes).toEqual([]);
  });

  it('ignora argumentos inválidos enviados pelo Groq', async () => {
    delete process.env.GEMINI_API_KEY;
    pool.query.mockResolvedValueOnce({ rows: [] });
    fetchMock
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          choices: [
            {
              message: {
                role: 'assistant',
                content: null,
                tool_calls: [
                  { id: 'call-1', type: 'function', function: { name: 'buscar_locais', arguments: '{quebrado' } },
                ],
              },
            },
          ],
        }),
      })
      .mockResolvedValueOnce(respostaGroq('Não encontrei locais.'));

    const res = await perguntar({ mensagem: 'Locais?' });

    expect(res.status).toBe(200);
    expect(pool.query.mock.calls[0][1]).toEqual([5]);
  });

  it('503 quando o Gemini e o Groq falham', async () => {
    fetchMock.mockResolvedValueOnce(respostaGemini('', 429)).mockResolvedValueOnce(respostaGroq('', 429));

    const res = await perguntar({ mensagem: 'Oi' });

    expect(res.status).toBe(503);
    expect(res.body.error).toBe('ASSISTENTE_INDISPONIVEL');
  });

  it('503 quando o Groq devolve resposta vazia', async () => {
    delete process.env.GEMINI_API_KEY;
    fetchMock.mockResolvedValueOnce(respostaGroq('  '));

    const res = await perguntar({ mensagem: 'Oi' });

    expect(res.status).toBe(503);
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