// Mesmo padrão de migration.test.js: sem Postgres real na suíte, valida a
// estrutura do SQL. A aplicação real é feita à mão com
// `psql -f db/migrations/004_notificacoes_de_volta.sql`.
const fs = require('fs');
const path = require('path');

const sql = fs.readFileSync(
  path.join(__dirname, '..', 'db', 'migrations', '004_notificacoes_de_volta.sql'),
  'utf8'
);

describe('migration 004_notificacoes_de_volta.sql', () => {
  it('adiciona a coluna de_volta em notificacoes de forma idempotente', () => {
    expect(sql).toMatch(/ALTER TABLE notificacoes ADD COLUMN IF NOT EXISTS de_volta/);
  });

  it('a coluna é BOOLEAN NOT NULL com default false', () => {
    expect(sql).toMatch(/de_volta BOOLEAN NOT NULL DEFAULT false/);
  });

  it('não altera o CHECK de tipo', () => {
    expect(sql).not.toMatch(/CHECK/i);
  });
});
