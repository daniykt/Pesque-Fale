// Mesmo padrão de migration-007.test.js: sem Postgres real na suíte,
// valida a estrutura do SQL. A aplicação real é feita com `npm run migrate`.
const fs = require('fs');
const path = require('path');

const pasta = path.join(__dirname, '..', 'db', 'migrations');
const ARQUIVO = '008_indices_performance.sql';
const sql = fs.readFileSync(path.join(pasta, ARQUIVO), 'utf8');

// Só os comandos: comentários (-- …) podem citar qualquer coisa.
const semComentarios = (texto) =>
  texto
    .split('\n')
    .filter((linha) => !linha.trim().startsWith('--'))
    .join('\n');

const comandos = semComentarios(sql);

// Um item por CREATE INDEX, com nome, tabela e colunas normalizados.
const indices = [
  ...comandos.matchAll(
    /CREATE\s+INDEX\s+(IF\s+NOT\s+EXISTS\s+)?(\w+)\s+ON\s+(?:public\.)?(\w+)\s+USING\s+btree\s*\(([^)]*)\)/gi
  ),
].map(([, ifNotExists, nome, tabela, colunas]) => ({
  ifNotExists: Boolean(ifNotExists),
  nome,
  tabela,
  colunas: colunas.replace(/\s+/g, ' ').trim(),
}));

// Nomes de índice já criados nas migrations anteriores: CREATE INDEX e as
// constraints (PRIMARY KEY / UNIQUE também criam índice com o nome delas).
const nomesAnteriores = fs
  .readdirSync(pasta)
  .filter((arquivo) => arquivo.endsWith('.sql') && arquivo < ARQUIVO)
  .flatMap((arquivo) => {
    const texto = semComentarios(fs.readFileSync(path.join(pasta, arquivo), 'utf8'));
    return [
      ...texto.matchAll(/CREATE\s+(?:UNIQUE\s+)?INDEX\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)/gi),
      ...texto.matchAll(/ADD\s+CONSTRAINT\s+(\w+)/gi),
    ].map((m) => m[1]);
  });

describe('migration 008_indices_performance.sql', () => {
  it('contém exatamente 4 CREATE INDEX, todos com IF NOT EXISTS', () => {
    expect(comandos.match(/CREATE\s+INDEX/gi)).toHaveLength(4);
    expect(indices).toHaveLength(4);
    indices.forEach((indice) => expect(indice.ifNotExists).toBe(true));
  });

  it('não usa CONCURRENTLY (o migrate.js roda em transação e o Postgres recusaria)', () => {
    expect(comandos).not.toMatch(/\bCONCURRENTLY\b/i);
  });

  it('não contém DROP, ALTER, DELETE, UPDATE nem INSERT', () => {
    expect(comandos).not.toMatch(/\b(DROP|ALTER|DELETE|UPDATE|INSERT)\b/i);
  });

  it.each([
    ['publicacoes_criado_em_idx', 'publicacoes', 'criado_em DESC'],
    ['usuario_seguidores_seguido_id_criado_em_idx', 'usuario_seguidores', 'seguido_id, criado_em DESC'],
    ['avaliacoes_ponto_id_criado_em_idx', 'avaliacoes', 'ponto_id, criado_em DESC'],
    ['chats_participante_b_idx', 'chats', 'participante_b'],
  ])('cria %s em %s (%s)', (nome, tabela, colunas) => {
    expect(indices).toContainEqual({ ifNotExists: true, nome, tabela, colunas });
  });

  it('nenhum nome de índice novo repete um nome das migrations 001 a 007', () => {
    // Com IF NOT EXISTS, um nome repetido faria o índice novo ser pulado em silêncio.
    expect(nomesAnteriores.length).toBeGreaterThan(0);
    expect(nomesAnteriores).toContain('publicacoes_autor_id_criado_em_idx');
    indices.forEach(({ nome }) => expect(nomesAnteriores).not.toContain(nome));
  });
});
