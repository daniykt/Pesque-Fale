const CHAVE_BASE64 = /base64/i;
const DATA_URI = /^data:[a-z]+\/[a-z0-9.+-]+;base64,/i;
const PROFUNDIDADE_MAXIMA = 4;

// Retorna o nome da chave que disparou a rejeição, ou null se o valor está
// limpo. Em estrutura aninhada devolve a chave mais próxima do valor: quem
// recebe o erro precisa saber qual campo corrigir, não o caminho inteiro.
function contemBase64(valor, chavePai = null, profundidade = 0) {
  if (valor === null || valor === undefined) return null;
  if (typeof valor === 'string') return DATA_URI.test(valor.trim()) ? chavePai : null;
  if (profundidade >= PROFUNDIDADE_MAXIMA) return null;

  if (Array.isArray(valor)) {
    for (const item of valor) {
      const chave = contemBase64(item, chavePai, profundidade + 1);
      if (chave !== null) return chave;
    }
    return null;
  }

  if (typeof valor === 'object') {
    for (const [chave, item] of Object.entries(valor)) {
      if (CHAVE_BASE64.test(chave)) return chave;
      const encontrada = contemBase64(item, chave, profundidade + 1);
      if (encontrada !== null) return encontrada;
    }
    return null;
  }

  return null;
}

function rejeitarBase64(req, res, next) {
  if (!req.body || typeof req.body !== 'object') return next();

  const campo = contemBase64(req.body);

  if (campo !== null) {
    return res.status(400).json({
      error: 'BASE64_NAO_PERMITIDO',
      message:
        'Imagem em base64 não é aceita. Envie o arquivo em POST /v1/publicacoes/imagens (multipart/form-data) e use a URL retornada em imagemUrl.',
      details: [
        {
          campo,
          mensagem: 'Campo não permitido. Envie a imagem via multipart/form-data.',
        },
      ],
    });
  }

  return next();
}

module.exports = rejeitarBase64;
