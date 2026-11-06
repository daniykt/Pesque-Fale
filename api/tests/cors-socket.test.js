const http = require('http');
const { Server } = require('socket.io');
const { lerOrigens, origemPermitida, opcoesSocket } = require('../src/config/cors-socket');

const PERMITIDAS = ['https://app.exemplo.com', 'https://outro.exemplo.com'];

describe('cors-socket — regra de origem', () => {
  it('lê a lista separada por vírgula, ignorando espaços e itens vazios', () => {
    expect(lerOrigens(' https://a.com, https://b.com ,,')).toEqual(['https://a.com', 'https://b.com']);
    expect(lerOrigens(undefined)).toEqual([]);
    expect(lerOrigens('')).toEqual([]);
  });

  it.each(['http://localhost', 'http://localhost:3000', 'http://localhost:54321', 'http://localhost:61987'])(
    'aceita %s (flutter run -d chrome usa porta aleatória)',
    (origem) => {
      expect(origemPermitida(origem, PERMITIDAS)).toBe(true);
    }
  );

  it.each(['http://127.0.0.1', 'http://127.0.0.1:8080', 'http://127.0.0.1:49152'])('aceita %s', (origem) => {
    expect(origemPermitida(origem, PERMITIDAS)).toBe(true);
  });

  it('aceita origem que está na lista', () => {
    expect(origemPermitida('https://app.exemplo.com', PERMITIDAS)).toBe(true);
    expect(origemPermitida('https://outro.exemplo.com', PERMITIDAS)).toBe(true);
  });

  it.each([
    'https://malicioso.com',
    'https://app.exemplo.com.malicioso.com',
    'http://localhost.malicioso.com',
    'http://localhost:3000.malicioso.com',
    'http://127.0.0.1.malicioso.com',
    'http://app.exemplo.com',
  ])('recusa %s', (origem) => {
    expect(origemPermitida(origem, PERMITIDAS)).toBe(false);
  });

  it.each([undefined, null, ''])('aceita requisição sem Origin (%p), como os apps nativos', (origem) => {
    expect(origemPermitida(origem, PERMITIDAS)).toBe(true);
  });
});

describe('cors-socket — opções do Socket.IO', () => {
  it.each([undefined, '', ' , '])('sem CORS_ORIGINS (%p) libera tudo, como antes', (valor) => {
    const opcoes = opcoesSocket(valor);

    expect(opcoes.cors).toEqual({ origin: '*', methods: ['GET', 'POST'] });
    expect(opcoes.allowRequest).toBeUndefined();
  });

  it('lê CORS_ORIGINS do ambiente quando nada é passado', () => {
    const anterior = process.env.CORS_ORIGINS;
    process.env.CORS_ORIGINS = 'https://app.exemplo.com';
    try {
      const opcoes = opcoesSocket();
      expect(typeof opcoes.allowRequest).toBe('function');
    } finally {
      if (anterior === undefined) delete process.env.CORS_ORIGINS;
      else process.env.CORS_ORIGINS = anterior;
    }
  });

  it('com CORS_ORIGINS, cors.origin e allowRequest usam a mesma regra', () => {
    const { cors, allowRequest } = opcoesSocket(PERMITIDAS.join(','));
    const resposta = (fn, valor) => {
      let resultado;
      fn(valor, (erro, ok) => {
        resultado = { erro, ok };
      });
      return resultado;
    };

    expect(resposta(cors.origin, 'https://app.exemplo.com')).toEqual({ erro: null, ok: true });
    expect(resposta(cors.origin, 'https://malicioso.com')).toEqual({ erro: null, ok: false });
    expect(resposta(allowRequest, { headers: { origin: 'http://localhost:61987' } }).ok).toBe(true);
    expect(resposta(allowRequest, { headers: {} }).ok).toBe(true);
    expect(resposta(allowRequest, { headers: { origin: 'https://malicioso.com' } })).toEqual({
      erro: 'ORIGEM_NAO_PERMITIDA',
      ok: false,
    });
  });
});

describe('cors-socket — handshake real', () => {
  let servidor;
  let io;
  let porta;

  async function subir(valorEnv) {
    servidor = http.createServer();
    io = new Server(servidor, opcoesSocket(valorEnv));
    await new Promise((resolve) => servidor.listen(0, '127.0.0.1', resolve));
    porta = servidor.address().port;
  }

  afterEach(async () => {
    io.close();
    await new Promise((resolve) => servidor.close(resolve));
  });

  function upgradeWebSocket(origem) {
    return new Promise((resolve, reject) => {
      const headers = {
        Connection: 'Upgrade',
        Upgrade: 'websocket',
        'Sec-WebSocket-Key': 'dGhlIHNhbXBsZSBub25jZQ==',
        'Sec-WebSocket-Version': '13',
      };
      if (origem) headers.Origin = origem;
      const req = http.request({
        host: '127.0.0.1',
        port: porta,
        path: '/socket.io/?EIO=4&transport=websocket',
        headers,
      });
      req.on('upgrade', (res, socket) => {
        socket.destroy();
        resolve(res.statusCode);
      });
      req.on('response', (res) => {
        res.resume();
        resolve(res.statusCode);
      });
      req.on('error', (err) => {
        if (err.code === 'ECONNRESET') resolve('recusado');
        else reject(err);
      });
      req.end();
    });
  }

  function polling(origem) {
    return new Promise((resolve, reject) => {
      const headers = origem ? { Origin: origem } : {};
      http
        .get(
          { host: '127.0.0.1', port: porta, path: '/socket.io/?EIO=4&transport=polling', headers },
          (res) => {
            res.resume();
            resolve(res.statusCode);
          }
        )
        .on('error', reject);
    });
  }

  it('com CORS_ORIGINS: WebSocket de origem fora da lista não conecta', async () => {
    await subir(PERMITIDAS.join(','));

    expect(await upgradeWebSocket('https://malicioso.com')).toBe(400);
  });

  it('com CORS_ORIGINS: WebSocket de localhost, da lista e sem Origin conecta', async () => {
    await subir(PERMITIDAS.join(','));

    expect(await upgradeWebSocket('http://localhost:61987')).toBe(101);
    expect(await upgradeWebSocket('https://app.exemplo.com')).toBe(101);
    expect(await upgradeWebSocket(undefined)).toBe(101);
  });

  it('com CORS_ORIGINS: polling de origem fora da lista é recusado', async () => {
    await subir(PERMITIDAS.join(','));

    expect(await polling('https://malicioso.com')).toBe(403);
    expect(await polling('https://app.exemplo.com')).toBe(200);
  });

  it('sem CORS_ORIGINS: qualquer origem conecta, como antes', async () => {
    await subir(undefined);

    expect(await upgradeWebSocket('https://malicioso.com')).toBe(101);
    expect(await polling('https://malicioso.com')).toBe(200);
  });
});
