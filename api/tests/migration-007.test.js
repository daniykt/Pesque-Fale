// Mesmo padrão de migration-006.test.js: sem Postgres real na suíte,
// valida a estrutura do SQL. A aplicação real é feita com `npm run migrate`.
const fs = require('fs');
const path = require('path');

const pasta = path.join(__dirname, '..', 'db', 'migrations');
const sql = fs.readFileSync(path.join(pasta, '007_fotos_tags_pontos.sql'), 'utf8');
const sql006 = fs.readFileSync(path.join(pasta, '006_seed_pontos.sql'), 'utf8');

// Só os comandos: comentários (-- …) podem citar qualquer coisa.
const semComentarios = (texto) =>
  texto
    .split('\n')
    .filter((linha) => !linha.trim().startsWith('--'))
    .join('\n');

const comandos = semComentarios(sql);

const CONTA_OFICIAL = '69397c7f-3249-451c-98b4-6fb7dda07e3e';
const SEM_FOTO = [
  '8c04c221-f1cb-479a-8db6-65dcf65c030a', // Tarumã
  'aa8c8704-0290-474c-855e-f486b5f64009', // Represa de Ibitinga
  'fcaf3bb0-5313-437e-8691-aff73a0b247e', // Represa de Bariri
];

// UUIDs dos pontos criados na 006 (todos menos a conta oficial).
const idsDa006 = [
  ...new Set(semComentarios(sql006).match(/'[0-9a-f]{8}-[0-9a-f-]{27}'/g) || []),
]
  .map((id) => id.slice(1, -1))
  .filter((id) => id !== CONTA_OFICIAL);

// Um bloco por UPDATE.
const updates = comandos
  .split(/UPDATE pontos_de_pesca/)
  .slice(1)
  .map((bloco) => ({
    id: (bloco.match(/WHERE id = '([0-9a-f-]{36})'/) || [])[1],
    criadoPor: (bloco.match(/criado_por = '([0-9a-f-]{36})'/) || [])[1],
    fotoCapa: (bloco.match(/foto_capa = '([^']+)'/) || [])[1],
    tags: ((bloco.match(/tags = ARRAY\[([^\]]*)\]/) || [])[1] || '')
      .split(',')
      .map((t) => t.trim().replace(/^'|'$/g, ''))
      .filter(Boolean),
  }));

describe('migration 007_fotos_tags_pontos.sql', () => {
  it('tem um UPDATE para cada um dos 10 pontos da 006', () => {
    expect(idsDa006).toHaveLength(10);
    expect(updates).toHaveLength(10);
    expect(updates.map((u) => u.id).sort()).toEqual([...idsDa006].sort());
  });

  it('todo UPDATE filtra pela conta oficial', () => {
    updates.forEach((u) => expect(u.criadoPor).toBe(CONTA_OFICIAL));
  });

  it('7 pontos com foto do Cloudinary de produção; Tarumã, Ibitinga e Bariri sem foto', () => {
    const comFoto = updates.filter((u) => u.fotoCapa);
    expect(comFoto).toHaveLength(7);
    comFoto.forEach((u) =>
      expect(u.fotoCapa).toMatch(/^https:\/\/res\.cloudinary\.com\/luvfmoi2\/image\/upload\//)
    );
    SEM_FOTO.forEach((id) => {
      expect(updates.find((u) => u.id === id).fotoCapa).toBeUndefined();
    });
  });

  it('tags: 1 a 3 por ponto, minúsculas, sem espaço e sem acento', () => {
    updates.forEach((u) => {
      expect(u.tags.length).toBeGreaterThanOrEqual(1);
      expect(u.tags.length).toBeLessThanOrEqual(3);
      u.tags.forEach((tag) => expect(tag).toMatch(/^[a-z0-9]+(-[a-z0-9]+)*$/));
    });
  });

  it('não abre transação própria (o npm run migrate já abre)', () => {
    expect(comandos).not.toMatch(/^\s*(BEGIN|COMMIT|ROLLBACK)\b/im);
  });

  it('só UPDATE: não cria, apaga nem altera schema', () => {
    expect(comandos).not.toMatch(/\b(INSERT|DELETE|ALTER|DROP|CREATE|TRUNCATE)\b/i);
  });

  it('não mexe em nome, descrição, coordenadas, tipo nem cidade', () => {
    expect(comandos).not.toMatch(/\b(nome|descricao|latitude|longitude|tipo|cidade|estado)\s*=/i);
  });
});
