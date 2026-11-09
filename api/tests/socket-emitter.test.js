describe('socket-emitter', () => {
  let emitter;

  beforeEach(() => {
    // O módulo guarda `io` em estado de módulo — cada teste começa sem init.
    jest.resetModules();
    emitter = require('../src/config/socket-emitter');
  });

  function fakeIo() {
    const emit = jest.fn();
    const to = jest.fn(() => ({ emit }));
    return { io: { to }, to, emit };
  }

  it('sem init → não lança, só avisa e não emite nada', () => {
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => {});

    expect(() => emitter.emitToUser('user-a', 'nova_notificacao', {})).not.toThrow();
    expect(warn).toHaveBeenCalledTimes(1);

    warn.mockRestore();
  });

  it('após init → emite pro room pessoal user:<id> com evento e payload', () => {
    const { io, to, emit } = fakeIo();
    emitter.init(io);

    emitter.emitToUser('user-a', 'nova_notificacao', { id: 1 });

    expect(to).toHaveBeenCalledWith('user:user-a');
    expect(emit).toHaveBeenCalledWith('nova_notificacao', { id: 1 });
  });

  it('emitToFeed sem init → não lança, só avisa e não emite nada', () => {
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => {});

    expect(() => emitter.emitToFeed('publicacao_criada', {})).not.toThrow();
    expect(warn).toHaveBeenCalledTimes(1);
    expect(warn.mock.calls[0][0]).toContain('emitToFeed');

    warn.mockRestore();
  });

  it('emitToFeed após init → emite pro room feed com evento e payload', () => {
    const { io, to, emit } = fakeIo();
    emitter.init(io);

    emitter.emitToFeed('publicacao_criada', { publicacaoId: 'pub-1' });

    expect(to).toHaveBeenCalledWith('feed');
    expect(emit).toHaveBeenCalledWith('publicacao_criada', { publicacaoId: 'pub-1' });
  });
});
