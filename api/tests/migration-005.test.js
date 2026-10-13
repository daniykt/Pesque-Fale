// Mesmo padrão de migration-004.test.js: sem Postgres real na suíte,
// valida a estrutura do SQL. A aplicação real é feita à mão com
// `psql -f db/migrations/005_limpar_notificacoes_mensagem.sql`.
const fs = require('fs');
const path = require('path');

const sql = fs.readFileSync(
  path.join(__dirname, '..', 'db', 'migrations', '005_limpar_notificacoes_mensagem.sql'),
  'utf8'
);

describe('migration 005_limpar_notificacoes_mensagem.sql', () => {
  it('apaga notificações do tipo mensagem', () => {
    expect(sql).toMatch(
      /DELETE FROM notificacoes WHERE tipo = 'mensagem'/
    );
  });

  it('a cláusula WHERE restringe por tipo (nunca é um DELETE sem WHERE)', () => {
    expect(sql).not.toMatch(/DELETE FROM notificacoes\s*;/);
  });

  it('não altera schema: sem ALTER, DROP ou CHECK', () => {
    expect(sql).not.toMatch(/ALTER\s+TABLE/i);
    expect(sql).not.toMatch(/DROP\s+(TABLE|COLUMN|CONSTRAINT)/i);
    expect(sql).not.toMatch(/CHECK/i);
  });

  it('não toca em outras tabelas além de notificacoes', () => {
    // Comentários (-- …) podem citar outras tabelas; os comandos SQL não.
    const comandos = sql
      .split('\n')
      .filter(linha => !linha.trim().startsWith('--'))
      .join('\n');
    expect(comandos).not.toMatch(/\b(usuarios|publicacoes|chats|mensagens|comentarios|curtidas|avaliacoes|usuario_seguidores)\b/i);
  });
});