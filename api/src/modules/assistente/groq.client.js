const { ErroIA } = require('./gemini.client');

const URL_GROQ = 'https://api.groq.com/openai/v1/chat/completions';
const MODELO_PADRAO = 'openai/gpt-oss-120b';
const TEMPO_LIMITE_MS = 15000;
const MAXIMO_RODADAS = 3;

function groqConfigurado() {
  return Boolean(process.env.GROQ_API_KEY);
}

function montarMensagens(instrucoes, historico, mensagem) {
  const anteriores = historico.map((item) => ({
    role: item.papel === 'assistente' ? 'assistant' : 'user',
    content: item.texto,
  }));
  return [
    { role: 'system', content: instrucoes },
    ...anteriores,
    { role: 'user', content: mensagem },
  ];
}

function converterFerramentas(declaracoes) {
  return declaracoes.map((declaracao) => ({
    type: 'function',
    function: {
      name: declaracao.name,
      description: declaracao.description,
      parameters: declaracao.parameters,
    },
  }));
}

function lerArgumentos(texto) {
  try {
    const argumentos = JSON.parse(texto || '{}');
    return argumentos && typeof argumentos === 'object' ? argumentos : {};
  } catch {
    return {};
  }
}

async function chamarGroq(corpo) {
  const controle = new AbortController();
  const temporizador = setTimeout(() => controle.abort(), TEMPO_LIMITE_MS);

  let resposta;
  try {
    resposta = await fetch(URL_GROQ, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
      },
      body: JSON.stringify(corpo),
      signal: controle.signal,
    });
  } catch (err) {
    if (err.name === 'AbortError') {
      throw new ErroIA('TEMPO_ESGOTADO', 'O Groq demorou demais para responder.');
    }
    throw new ErroIA('FALHA_CONEXAO', 'Não foi possível falar com o Groq.');
  } finally {
    clearTimeout(temporizador);
  }

  if (resposta.status === 429) {
    throw new ErroIA('LIMITE_IA', 'Limite do plano gratuito do Groq atingido.');
  }
  if (!resposta.ok) {
    throw new ErroIA('FALHA_IA', `O Groq respondeu com status ${resposta.status}.`);
  }

  const dados = await resposta.json();
  return dados?.choices?.[0]?.message ?? { role: 'assistant', content: '' };
}

async function gerarRespostaGroq({ instrucoes, historico, mensagem, ferramentas }) {
  const mensagens = montarMensagens(instrucoes, historico, mensagem);
  const modelo = process.env.GROQ_MODEL || MODELO_PADRAO;

  for (let rodada = 0; rodada < MAXIMO_RODADAS; rodada++) {
    const corpo = { model: modelo, messages: mensagens, temperature: 0.4 };
    if (ferramentas) {
      corpo.tools = converterFerramentas(ferramentas.declaracoes);
    }

    const resposta = await chamarGroq(corpo);
    const chamadas = resposta.tool_calls ?? [];

    if (chamadas.length === 0 || !ferramentas) {
      const texto = (resposta.content ?? '').trim();
      if (!texto) {
        throw new ErroIA('RESPOSTA_VAZIA', 'O Groq não devolveu texto.');
      }
      return texto;
    }

    mensagens.push({ role: 'assistant', content: resposta.content ?? null, tool_calls: chamadas });

    for (const chamada of chamadas) {
      const resultado = await ferramentas.executar(
        chamada.function.name,
        lerArgumentos(chamada.function.arguments)
      );
      mensagens.push({ role: 'tool', tool_call_id: chamada.id, content: JSON.stringify(resultado) });
    }
  }

  throw new ErroIA('RODADAS_ESGOTADAS', 'O Groq não concluiu a resposta.');
}

module.exports = { groqConfigurado, gerarRespostaGroq };