const fs = require('fs');
const path = require('path');

const sql = fs.readFileSync(
  path.join(__dirname, '..', 'db', 'migrations', '001_schema_inicial.sql'),
  'utf8'
);

const TABELAS_BASE = [
  'usuarios',
  'usuario_seguidores',
  'pontos_de_pesca',
  'avaliacoes',
  'publicacoes',
  'eventos',
  'chats',
  'mensagens',
  'notificacoes',
];

describe('migration 001_schema_inicial.sql', () => {
  it('roda dentro de uma transação', () => {
    expect(sql.trimStart()).toMatch(/^BEGIN;/);
    expect(sql.trimEnd()).toMatch(/COMMIT;$/);
  });

  it('habilita as extensões pgcrypto e postgis', () => {
    expect(sql).toMatch(/CREATE EXTENSION IF NOT EXISTS pgcrypto/);
    expect(sql).toMatch(/CREATE EXTENSION IF NOT EXISTS postgis/);
  });

  it.each(TABELAS_BASE)('cria a tabela base %s', (tabela) => {
    expect(sql).toMatch(new RegExp(`CREATE TABLE public\\.${tabela} \\(`));
  });

  it('não cria tabelas nem triggers que pertencem à migration 003', () => {
    expect(sql).not.toMatch(/CREATE TABLE public\.curtidas/);
    expect(sql).not.toMatch(/CREATE TABLE public\.comentarios/);
    expect(sql).not.toMatch(/atualizar_curtidas_count|atualizar_comentarios_count/);
    expect(sql).not.toMatch(/\btags text\[\] DEFAULT/);
  });

  it('não cria a coluna que pertence à migration 004', () => {
    expect(sql).not.toMatch(/de_volta/);
  });

  it('mantém em publicacoes os contadores que a migration 003 usa', () => {
    expect(sql).toMatch(/curtidas_count integer DEFAULT 0/);
    expect(sql).toMatch(/comentarios_count integer DEFAULT 0/);
  });

  it('cria o índice geográfico usado na busca de pontos por distância', () => {
    expect(sql).toMatch(/pontos_de_pesca_st_makepoint_idx ON public\.pontos_de_pesca USING gist/);
  });

  it('não contém comandos exclusivos do psql nem de versões recentes do Postgres', () => {
    expect(sql).not.toMatch(/\\restrict|\\unrestrict/);
    expect(sql).not.toMatch(/transaction_timeout/);
    expect(sql).not.toMatch(/OWNER TO/);
  });
});