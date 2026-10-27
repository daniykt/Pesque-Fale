jest.mock('../src/config/database', () => ({ query: jest.fn() }));
jest.mock('../src/config/socket-emitter', () => ({ init: jest.fn(), emitToUser: jest.fn() }));

const pool = require('../src/config/database');
const { emitToUser } = require('../src/config/socket-emitter');
const initChatGateway = require('../src/modules/chat/chat.gateway');

const A = 'aaa-user';
const B = 'bbb-user';
const CHAT_ID = `${A}_${B}`;

// Fake mínimo do Server do Socket.IO: guarda o handler de `connection` e
// registra tudo que for emitido via io.to(room).emit(...).
function fakeIo() {
  const emitidosEmRoom = [];
  let aoConectar;
  return {
    emitidosEmRoom,
    use: jest.fn(),
    on: jest.fn((evento, handler) => {
      if (evento === 'connection') aoConectar = handler;
    }),
    to: jest.fn((room) => ({
      emit: (evento, payload) => emitidosEmRoom.push({ room, evento, payload }),
    })),
    conectar(socket) {
      aoConectar(socket);
    },
  };
}

function fakeSocket(usuarioId) {
  const handlers = {};
  return {
    usuario: { id: usuarioId },
    on: (evento, handler) => {
      handlers[evento] = handler;
    },
    join: jest.fn(),
    emit: jest.fn(),
    to: jest.fn(() => ({ emit: jest.fn() })),
    disparar: (evento, dados) => handlers[evento](dados),
  };
}

// Fake de `mensagens`: responde as queries do handler pelo SQL, contando as
// linhas inseridas pra que o COUNT(*) reflita o histórico do chat.
// `falharEm` (regex) faz a query correspondente lançar, simulando queda do banco.
function comBanco({ mensagensExistentes = 0, falharEm = null } = {}) {
  let total = mensagensExistentes;
  pool.query.mockImplementation(async (sql, params) => {
    if (falharEm && falharEm.test(sql)) {
      throw new Error('falha simulada no banco');
    }
    if (/SELECT nome FROM usuarios/.test(sql)) {
      return { rows: [{ nome: 'Ana' }] };
    }
    if (/INSERT INTO mensagens/.test(sql)) {
      total++;
      const [chatId, userId, nome, texto] = params;
      return {
        rows: [{
          id: `msg-${total}`,
          chat_id: chatId,
          user_id: userId,
          nome,
          texto,
          status: 'enviado',
          criado_em: '2026-10-27T12:00:00.000Z',
        }],
      };
    }
    if (/SELECT COUNT\(\*\) FROM mensagens/.test(sql)) {
      return { rows: [{ count: String(total) }] };
    }
    if (/SELECT id, nome, username, foto_perfil FROM usuarios/.test(sql)) {
      return { rows: [{ id: A, nome: 'Ana', username: 'ana', foto_perfil: 'http://foto/ana.png' }] };
    }
    if (/UPDATE mensagens SET status = 'visto'/.test(sql)) {
      return { rows: [] };
    }
    if (/AS mutuo/.test(sql)) {
      return { rows: [{ mutuo: true }] };
    }
    if (/INSERT INTO chats/.test(sql)) {
      return { rows: [] };
    }
    if (/SELECT \* FROM mensagens/.test(sql)) {
      return { rows: [] };
    }
    throw new Error(`query inesperada: ${sql}`);
  });
}

function eventosEmitidos(evento) {
  return emitToUser.mock.calls.filter(([, e]) => e === evento);
}

async function enviarComo(usuarioId, texto) {
  const io = fakeIo();
  initChatGateway(io);
  const socket = fakeSocket(usuarioId);
  io.conectar(socket);
  // Simula o estado deixado por `entrar_chat`, que não é o foco aqui.
  socket.chatId = CHAT_ID;
  await socket.disparar('enviar_mensagem', { texto });
  return { io, socket };
}

describe('chat.gateway — enviar_mensagem emite eventos realtime', () => {
  beforeEach(() => {
    pool.query.mockReset();
    emitToUser.mockReset();
  });

  it('primeira mensagem dispara nova_conversa pros dois usuários', async () => {
    comBanco({ mensagensExistentes: 0 });

    await enviarComo(A, 'oi');

    const chamadas = eventosEmitidos('nova_conversa');
    expect(chamadas.map(([userId]) => userId).sort()).toEqual([A, B]);
    const [, , payload] = chamadas[0];
    expect(payload).toEqual({
      conversaId: CHAT_ID,
      remetente: { id: A, nome: 'Ana', username: 'ana', fotoUrl: 'http://foto/ana.png' },
      ultimaMensagem: {
        id: 'msg-1',
        chatId: CHAT_ID,
        userId: A,
        nome: 'Ana',
        texto: 'oi',
        status: 'enviado',
        criadoEm: '2026-10-27T12:00:00.000Z',
      },
    });
  });

  it('nova_conversa sai antes de nova_mensagem_em_conversa', async () => {
    comBanco({ mensagensExistentes: 0 });

    await enviarComo(A, 'oi');

    const eventos = emitToUser.mock.calls.map(([, e]) => e);
    expect(eventos.lastIndexOf('nova_conversa'))
      .toBeLessThan(eventos.indexOf('nova_mensagem_em_conversa'));
  });

  it('mensagem adicional NÃO dispara nova_conversa de novo', async () => {
    comBanco({ mensagensExistentes: 3 });

    await enviarComo(B, 'tudo bem?');

    expect(eventosEmitidos('nova_conversa')).toHaveLength(0);
  });

  it.each([
    ['primeira', 0],
    ['adicional', 5],
  ])('mensagem %s dispara nova_mensagem_em_conversa pros dois', async (_, existentes) => {
    comBanco({ mensagensExistentes: existentes });

    await enviarComo(B, '  bora pescar  ');

    const chamadas = eventosEmitidos('nova_mensagem_em_conversa');
    expect(chamadas.map(([userId]) => userId).sort()).toEqual([A, B]);
    for (const [, , payload] of chamadas) {
      expect(payload).toEqual({
        conversaId: CHAT_ID,
        previewTexto: 'bora pescar',
        timestamp: '2026-10-27T12:00:00.000Z',
        remetenteId: B,
      });
    }
  });

  it('nova_mensagem continua indo pro room do chat (tela aberta)', async () => {
    comBanco({ mensagensExistentes: 0 });

    const { io } = await enviarComo(A, 'oi');

    expect(io.emitidosEmRoom).toEqual([
      expect.objectContaining({
        room: CHAT_ID,
        evento: 'nova_mensagem',
        payload: expect.objectContaining({ id: 'msg-1', texto: 'oi', userId: A }),
      }),
    ]);
  });

  describe('falhas', () => {
    let consoleError;

    beforeEach(() => {
      consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});
    });

    afterEach(() => consoleError.mockRestore());

    function inseriu() {
      return pool.query.mock.calls.some(([sql]) => /INSERT INTO mensagens/.test(sql));
    }

    it('quando contarMensagens falha após o insert, a mensagem continua salva e nova_mensagem é emitido', async () => {
      comBanco({ mensagensExistentes: 0, falharEm: /SELECT COUNT\(\*\) FROM mensagens/ });

      const { io, socket } = await enviarComo(A, 'oi');

      expect(inseriu()).toBe(true);
      expect(io.emitidosEmRoom).toEqual([
        expect.objectContaining({ room: CHAT_ID, evento: 'nova_mensagem' }),
      ]);
      expect(socket.emit).not.toHaveBeenCalledWith('erro', expect.anything());
      expect(eventosEmitidos('nova_conversa')).toHaveLength(0);
      expect(consoleError).toHaveBeenCalledWith(
        '[chat] erro pós-insert, mensagem já salva:',
        expect.any(Error)
      );
    });

    it('quando buscarDadosRemetente falha na primeira mensagem, nova_mensagem_em_conversa ainda é emitido', async () => {
      comBanco({
        mensagensExistentes: 0,
        falharEm: /SELECT id, nome, username, foto_perfil FROM usuarios/,
      });

      const { io, socket } = await enviarComo(A, 'oi');

      expect(eventosEmitidos('nova_conversa')).toHaveLength(0);
      expect(eventosEmitidos('nova_mensagem_em_conversa').map(([userId]) => userId).sort())
        .toEqual([A, B]);
      expect(io.emitidosEmRoom).toHaveLength(1);
      expect(socket.emit).not.toHaveBeenCalledWith('erro', expect.anything());
    });

    it('quando o insert falha, emite erro pro remetente e nada mais', async () => {
      comBanco({ falharEm: /INSERT INTO mensagens/ });

      const { io, socket } = await enviarComo(A, 'oi');

      expect(socket.emit).toHaveBeenCalledWith('erro', { message: 'Erro ao enviar mensagem.' });
      expect(emitToUser).not.toHaveBeenCalled();
      expect(io.emitidosEmRoom).toHaveLength(0);
    });
  });

  it('sem chat aberto ou texto vazio não emite nada', async () => {
    comBanco();
    const io = fakeIo();
    initChatGateway(io);
    const socket = fakeSocket(A);
    io.conectar(socket);

    await socket.disparar('enviar_mensagem', { texto: 'oi' });
    socket.chatId = CHAT_ID;
    await socket.disparar('enviar_mensagem', { texto: '   ' });

    expect(emitToUser).not.toHaveBeenCalled();
    expect(io.emitidosEmRoom).toHaveLength(0);
  });
});

describe('chat.gateway — leitura emite conversa_lida', () => {
  beforeEach(() => {
    pool.query.mockReset();
    emitToUser.mockReset();
  });

  async function marcarVistoComo(usuarioId) {
    const io = fakeIo();
    initChatGateway(io);
    const socket = fakeSocket(usuarioId);
    io.conectar(socket);
    socket.chatId = CHAT_ID;
    await socket.disparar('marcar_visto');
    return { io, socket };
  }

  it('marcar_visto emite conversa_lida pros rooms pessoais dos dois', async () => {
    comBanco();

    await marcarVistoComo(B);

    const chamadas = eventosEmitidos('conversa_lida');
    expect(chamadas.map(([userId]) => userId).sort()).toEqual([A, B]);
  });

  it('payload de conversa_lida tem conversaId, lidaPor e quandoEm', async () => {
    comBanco();

    await marcarVistoComo(B);

    for (const [, , payload] of eventosEmitidos('conversa_lida')) {
      expect(payload).toEqual({
        conversaId: CHAT_ID,
        lidaPor: B,
        quandoEm: expect.any(String),
      });
      expect(new Date(payload.quandoEm).toISOString()).toBe(payload.quandoEm);
    }
  });

  it('mensagens_vistas continua indo pro room do chat', async () => {
    comBanco();

    const { io } = await marcarVistoComo(B);

    expect(io.emitidosEmRoom).toEqual([
      { room: CHAT_ID, evento: 'mensagens_vistas', payload: { chatId: CHAT_ID, porId: B } },
    ]);
  });

  it('entrar_chat também emite conversa_lida (abrir a conversa marca como vista)', async () => {
    comBanco();
    const io = fakeIo();
    initChatGateway(io);
    const socket = fakeSocket(B);
    io.conectar(socket);

    await socket.disparar('entrar_chat', { outroId: A });

    expect(socket.emit).toHaveBeenCalledWith('historico', { chatId: CHAT_ID, mensagens: [] });
    const chamadas = eventosEmitidos('conversa_lida');
    expect(chamadas.map(([userId]) => userId).sort()).toEqual([A, B]);
    expect(chamadas[0][2]).toEqual(expect.objectContaining({ conversaId: CHAT_ID, lidaPor: B }));
  });

  it('sem chat aberto, marcar_visto não faz nada', async () => {
    comBanco();
    const io = fakeIo();
    initChatGateway(io);
    const socket = fakeSocket(B);
    io.conectar(socket);

    await socket.disparar('marcar_visto');

    expect(pool.query).not.toHaveBeenCalled();
    expect(emitToUser).not.toHaveBeenCalled();
    expect(io.emitidosEmRoom).toHaveLength(0);
  });

  describe('falhas', () => {
    let consoleError;

    beforeEach(() => {
      consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});
    });

    afterEach(() => consoleError.mockRestore());

    it('quando marcarComoVistas falha, não emite mensagens_vistas nem conversa_lida', async () => {
      comBanco({ falharEm: /UPDATE mensagens SET status = 'visto'/ });

      const { io, socket } = await marcarVistoComo(B);

      expect(io.emitidosEmRoom).toHaveLength(0);
      expect(emitToUser).not.toHaveBeenCalled();
      expect(socket.emit).not.toHaveBeenCalled();
      expect(consoleError).toHaveBeenCalled();
    });

    it('falha no emit de conversa_lida só loga; mensagens_vistas já saiu', async () => {
      comBanco();
      emitToUser.mockImplementation(() => {
        throw new Error('falha simulada no emit');
      });

      const { io, socket } = await marcarVistoComo(B);

      expect(io.emitidosEmRoom).toEqual([
        expect.objectContaining({ room: CHAT_ID, evento: 'mensagens_vistas' }),
      ]);
      expect(socket.emit).not.toHaveBeenCalledWith('erro', expect.anything());
      expect(consoleError).toHaveBeenCalledWith(
        '[chat] erro pós-update ao emitir conversa_lida:',
        expect.any(Error)
      );
    });
  });
});
