jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const pool = require('../src/config/database');
const { verificarMutualFollow } = require('../src/modules/chat/chat.gateway');

const A = 'user-a';
const B = 'user-b';

// Fake de usuario_seguidores: cada linha é [seguidor_id, seguido_id].
// Responde checando cada direção de forma independente, como o
// EXISTS ... AND EXISTS faz no Postgres. O SQL real é validado à parte,
// no teste estrutural — com o pool mockado ele nunca é executado.
function comSeguidores(linhas) {
  const existe = (seguidor, seguido) =>
    linhas.some(([s, d]) => s === seguidor && d === seguido);
  pool.query.mockImplementation(async (_sql, [uid1, uid2]) => ({
    rows: [{ mutuo: existe(uid1, uid2) && existe(uid2, uid1) }],
  }));
}

describe('verificarMutualFollow', () => {
  beforeEach(() => pool.query.mockReset());

  it('checa as duas direções com EXISTS independentes, sem COUNT nem OR', async () => {
    comSeguidores([]);

    await verificarMutualFollow(A, B);

    const [sql, params] = pool.query.mock.calls[0];
    expect(sql).toMatch(
      /EXISTS\s*\(\s*SELECT 1 FROM usuario_seguidores WHERE seguidor_id = \$1 AND seguido_id = \$2\s*\)\s*AND EXISTS\s*\(\s*SELECT 1 FROM usuario_seguidores WHERE seguidor_id = \$2 AND seguido_id = \$1\s*\)/
    );
    expect(sql).not.toMatch(/COUNT|\bOR\b/i);
    expect(params).toEqual([A, B]);
  });

  it('sem follow → false', async () => {
    comSeguidores([]);

    expect(await verificarMutualFollow(A, B)).toBe(false);
  });

  it('follow unilateral (A→B) → false', async () => {
    comSeguidores([[A, B]]);

    expect(await verificarMutualFollow(A, B)).toBe(false);
    expect(await verificarMutualFollow(B, A)).toBe(false);
  });

  it('follow mútuo (A→B e B→A) → true, em qualquer ordem', async () => {
    comSeguidores([[A, B], [B, A]]);

    expect(await verificarMutualFollow(A, B)).toBe(true);
    expect(await verificarMutualFollow(B, A)).toBe(true);
  });

  it('duplicata unilateral (A→B duas vezes, sem B→A) → false', async () => {
    comSeguidores([[A, B], [A, B]]);

    expect(await verificarMutualFollow(A, B)).toBe(false);
  });
});
