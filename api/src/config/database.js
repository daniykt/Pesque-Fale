const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // Session pooler do Supabase: cada conexão aqui ocupa uma vaga do pool size
  // de lá, dividida com o Storage, o DBeaver e o migrate. 8 deixa folga.
  max: 8,
  // O padrão (10 s) fechava a conexão em qualquer pausa e a próxima requisição
  // pagava ~450–730 ms para reabrir (Render EUA → Supabase SP). Medido na #273.
  idleTimeoutMillis: 5 * 60 * 1000,
  // O padrão (0) espera para sempre se o banco não responder.
  connectionTimeoutMillis: 10 * 1000,
  // Detecta conexão derrubada por baixo; o pool.on('error') trata o erro.
  keepAlive: true,
});

pool.on('error', (err) => {
  console.error('[database] erro em conexão ociosa do pool:', err.message);
});

module.exports = pool;