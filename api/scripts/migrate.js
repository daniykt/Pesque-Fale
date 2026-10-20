/**
 * Runner de migrations — aplica, em ordem, os arquivos .sql de
 * db/migrations/ que ainda não constam na tabela schema_migrations.
 *
 * Cada migration roda na própria transação, junto com o registro em
 * schema_migrations: ou entram as duas coisas, ou nenhuma. Na primeira
 * falha o script desfaz aquela migration, para e sai com código 1.
 * É seguro rodar várias vezes: o que já foi aplicado é pulado.
 *
 * Uso (de dentro de api/):
 *   npm run migrate
 */

const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

require('dotenv').config({ path: path.join(__dirname, '..', '.env'), quiet: true });

const MIGRATIONS_DIR = path.join(__dirname, '..', 'db', 'migrations');

async function main() {
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL não definida. Configure-a em api/.env ou no ambiente.');
  }

  const client = new Client({ connectionString: process.env.DATABASE_URL });

  try {
    await client.connect();
  } catch (err) {
    throw new Error(`não foi possível conectar no banco: ${err.message}`);
  }

  try {
    await client.query(
      `CREATE TABLE IF NOT EXISTS schema_migrations (
         id SERIAL PRIMARY KEY,
         filename VARCHAR(255) NOT NULL UNIQUE,
         executed_at TIMESTAMP NOT NULL DEFAULT NOW()
       )`
    );

    const arquivos = fs
      .readdirSync(MIGRATIONS_DIR)
      .filter((arquivo) => arquivo.endsWith('.sql'))
      .sort();

    const { rows } = await client.query('SELECT filename FROM schema_migrations');
    const aplicadas = new Set(rows.map((row) => row.filename));

    for (const arquivo of arquivos) {
      if (aplicadas.has(arquivo)) {
        console.log(`⏭️  já aplicada: ${arquivo}`);
        continue;
      }

      const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, arquivo), 'utf8');

      try {
        await client.query('BEGIN');
        await client.query(sql);
        await client.query('INSERT INTO schema_migrations (filename) VALUES ($1)', [arquivo]);
        await client.query('COMMIT');
      } catch (err) {
        // Se a conexão caiu, o ROLLBACK também falha; o erro que importa é o original.
        await client.query('ROLLBACK').catch(() => {});
        throw new Error(`erro em ${arquivo}: ${err.message}`);
      }

      console.log(`✅ aplicada: ${arquivo}`);
    }
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  console.log(`❌ ${err.message}`);
  process.exitCode = 1;
});
