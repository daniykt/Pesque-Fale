const ORIGEM_LOCAL = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;

function lerOrigens(valor) {
  return (valor ?? '')
    .split(',')
    .map((origem) => origem.trim())
    .filter(Boolean);
}

function origemPermitida(origem, permitidas) {
  if (!origem) return true;
  if (ORIGEM_LOCAL.test(origem)) return true;
  return permitidas.includes(origem);
}

function opcoesSocket(valorEnv = process.env.CORS_ORIGINS) {
  const permitidas = lerOrigens(valorEnv);
  const methods = ['GET', 'POST'];

  if (permitidas.length === 0) {
    return { cors: { origin: '*', methods } };
  }

  return {
    cors: {
      origin: (origem, callback) => callback(null, origemPermitida(origem, permitidas)),
      methods,
    },
    allowRequest: (req, callback) => {
      const ok = origemPermitida(req.headers.origin, permitidas);
      callback(ok ? null : 'ORIGEM_NAO_PERMITIDA', ok);
    },
  };
}

module.exports = { lerOrigens, origemPermitida, opcoesSocket };
