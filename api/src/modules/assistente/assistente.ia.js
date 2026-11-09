const { geminiConfigurado, gerarResposta } = require('./gemini.client');
const { groqConfigurado, gerarRespostaGroq } = require('./groq.client');
const { criarFerramentas } = require('./assistente.ferramentas');

function iaConfigurada() {
  return geminiConfigurado() || groqConfigurado();
}

async function tentar(gerador, pedido) {
  const ferramentas = criarFerramentas();
  const resposta = await gerador({ ...pedido, ferramentas });
  return { resposta, acoes: ferramentas.acoes };
}

async function responder(pedido) {
  if (!geminiConfigurado()) {
    return tentar(gerarRespostaGroq, pedido);
  }

  try {
    return await tentar(gerarResposta, pedido);
  } catch (err) {
    if (!groqConfigurado()) throw err;
    console.error('Gemini falhou, usando o Groq:', err.codigo ?? 'DESCONHECIDO', err.message);
    return tentar(gerarRespostaGroq, pedido);
  }
}

module.exports = { iaConfigurada, responder };