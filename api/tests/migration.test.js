// A suíte não tem acesso a um Postgres real neste ambiente, então os triggers
// não podem ser exercitados em runtime aqui. Esta suíte valida a estrutura da
// migration; a execução real dos triggers deve ser verificada manualmente
// (`psql -f db/migrations/003_curtidas_comentarios.sql` + INSERT/DELETE de
// curtidas/comentarios) contra um Postgres local antes do merge.
const fs = require('fs');
const path = require('path');

const sql = fs.readFileSync(
  path.join(__dirname, '..', 'db', 'migrations', '003_curtidas_comentarios.sql'),
  'utf8'
);

describe('migration 003_curtidas_comentarios.sql', () => {
  it('adiciona a coluna tags em publicacoes', () => {
    expect(sql).toMatch(/ALTER TABLE publicacoes ADD COLUMN IF NOT EXISTS tags/);
  });

  it('cria a tabela curtidas com chave primária composta idempotente', () => {
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS curtidas/);
    expect(sql).toMatch(/PRIMARY KEY \(usuario_id, publicacao_id\)/);
  });

  it('cria a tabela comentarios com CHECK de tamanho de texto', () => {
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS comentarios/);
    expect(sql).toMatch(/CHECK \(char_length\(texto\) BETWEEN 1 AND 500\)/);
  });

  it('cria os triggers de contagem para curtidas e comentarios', () => {
    expect(sql).toMatch(/CREATE TRIGGER trg_curtidas_count/);
    expect(sql).toMatch(/AFTER INSERT OR DELETE ON curtidas/);
    expect(sql).toMatch(/CREATE TRIGGER trg_comentarios_count/);
    expect(sql).toMatch(/AFTER INSERT OR DELETE ON comentarios/);
  });

  it('os triggers nunca deixam os contadores ficarem negativos', () => {
    expect(sql).toMatch(/GREATEST\(curtidas_count - 1, 0\)/);
    expect(sql).toMatch(/GREATEST\(comentarios_count - 1, 0\)/);
  });
});
