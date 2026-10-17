const URL_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';
const MODELO_PADRAO = 'gemini-3.8-flash';
const TEMPO_LIMITE_MS = 15000;

class ErroIA extends Error {
  constructor(codigo, mensagem) {
    super(mensagem);
    this.codigo = codigo;
  }
}

function geminiConfigurado() {
  return Boolean(process.env.GEMINI_API_KEY);
}

function montarConteudos(historico, mensagem) {
  const anteriores = historico.map((item) => ({
    role: item.papel === 'assistente' ? 'model' : 'user',
    parts: [{ text: item.texto }],
  }));
  return [...anteriores, { role: 'user', parts: [{ text: mensagem }] }];
}

async function gerarResposta({ instrucoes, historico, mensagem }) {
  const modelo = process.env.GEMINI_MODEL || MODELO_PADRAO;
  const controle = new AbortController();
  const temporizador = setTimeout(() => controle.abort(), TEMPO_LIMITE_MS);

  let resposta;
  try {
    resposta = await fetch(`${URL_BASE}/${modelo}:generateContent`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': process.env.GEMINI_API_KEY,
      },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: instrucoes }] },
        contents: montarConteudos(historico, mensagem),
        generationConfig: { temperature: 0.4 },
      }),
      signal: controle.signal,
    });
  } catch (err) {
    if (err.name === 'AbortError') {
      throw new ErroIA('TEMPO_ESGOTADO', 'A IA demorou demais para responder.');
    }
    throw new ErroIA('FALHA_CONEXAO', 'Não foi possível falar com a IA.');
  } finally {
    clearTimeout(temporizador);
  }

  if (resposta.status === 429) {
    throw new ErroIA('LIMITE_IA', 'Limite do plano gratuito da IA atingido.');
  }
  if (!resposta.ok) {
    throw new ErroIA('FALHA_IA', `A IA respondeu com status ${resposta.status}.`);
  }

  const corpo = await resposta.json();
  const partes = corpo?.candidates?.[0]?.content?.parts ?? [];
  const texto = partes
    .map((parte) => parte.text ?? '')
    .join('')
    .trim();

  if (!texto) {
    throw new ErroIA('RESPOSTA_VAZIA', 'A IA não devolveu texto.');
  }
  return texto;
}

module.exports = { ErroIA, geminiConfigurado, gerarResposta };