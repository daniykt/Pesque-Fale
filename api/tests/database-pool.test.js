// URL fictícia: o Pool do pg não conecta até a primeira query, e este teste
// não faz nenhuma. Definir antes do require impede o dotenv de usar a do .env.
process.env.DATABASE_URL = 'postgres://teste:teste@localhost:5432/teste';

const pool = require('../src/config/database');

describe('pool do postgres — erro em conexão ociosa', () => {
  let consoleErrorSpy;

  beforeEach(() => {
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    consoleErrorSpy.mockRestore();
  });

  afterAll(async () => {
    await pool.end();
  });

  it('tem handler de error registrado', () => {
    expect(pool.listenerCount('error')).toBeGreaterThan(0);
  });

  it('erro emitido pelo pool não lança exceção e é logado', () => {
    expect(() => pool.emit('error', new Error('conexão perdida'))).not.toThrow();
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      '[database] erro em conexão ociosa do pool:',
      'conexão perdida'
    );
  });
});
