const { montarInstrucoes } = require('./assistente.prompt');
const { geminiConfigurado, gerarResposta } = require('./gemini.client');
const { consumir } = require('./limite');
const { criarFerramentas } = require('./assistente.ferramentas');

const TAMANHO_MAXIMO_MENSAGEM = 500;
const TAMANHO_MAXIMO_HISTORICO = 6;
const TAMANHO_MAXIMO_TEXTO_HISTORICO = 2000;
const PAPEIS_VALIDOS = ['usuario', 'assistente'];

function validar({ mensagem, historico, tela }) {
  const details = [];

  if (typeof mensagem !== 'string' || mensagem.trim().length === 0) {
    details.push({ campo: 'mensagem', mensagem: 'Mensagem é obrigatória.' });
  } else if (mensagem.length > TAMANHO_MAXIMO_MENSAGEM) {
    details.push({
      campo: 'mensagem',
      mensagem: `Mensagem deve ter no máximo ${TAMANHO_MAXIMO_MENSAGEM} caracteres.`,
    });
  }

  if (historico !== undefined) {
    const valido =
      Array.isArray(historico) &&
      historico.every(
        (item) =>
          item &&
          PAPEIS_VALIDOS.includes(item.papel) &&
          typeof item.texto === 'string' &&
          item.texto.length <= TAMANHO_MAXIMO_TEXTO_HISTORICO
      );
    if (!valido) {
      details.push({
        campo: 'historico',
        mensagem: 'Histórico deve ser uma lista de { papel, texto }.',
      });
    }
  }

  if (tela !== undefined && (typeof tela !== 'string' || tela.length > 50)) {
    details.push({ campo: 'tela', mensagem: 'Tela inválida.' });
  }

  return details;
}

async function conversar(req, res) {
  const { mensagem, historico, tela } = req.body ?? {};

  const details = validar({ mensagem, historico, tela });
  if (details.length > 0) {
    return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Verifique os campos.', details });
  }

  if (!geminiConfigurado()) {
    return res.status(503).json({
      error: 'ASSISTENTE_INDISPONIVEL',
      message: 'O assistente não está disponível no momento.',
    });
  }

  if (!consumir(req.usuario.id)) {
    return res.status(429).json({
      error: 'LIMITE_ASSISTENTE',
      message: 'Você fez muitas perguntas seguidas. Tente de novo daqui a pouco.',
    });
  }

  const ferramentas = criarFerramentas();

  try {
    const resposta = await gerarResposta({
      instrucoes: montarInstrucoes(tela),
      historico: (historico ?? []).slice(-TAMANHO_MAXIMO_HISTORICO),
      mensagem: mensagem.trim(),
      ferramentas,
    });
    return res.status(200).json({ data: { resposta, acoes: ferramentas.acoes } });
  } catch (err) {
    console.error('Erro no assistente:', err.codigo ?? 'DESCONHECIDO', err.message);
    return res.status(503).json({
      error: 'ASSISTENTE_INDISPONIVEL',
      message: 'O assistente está descansando um pouquinho. Tente de novo em alguns minutos.',
    });
  }
}

module.exports = { conversar };