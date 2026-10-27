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
function comBanco({ mensagensExistentes = 0 } = {}) {
  let total = mensagensExistentes;
  pool.query.mockImplementation(async (sql, params) => {
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
