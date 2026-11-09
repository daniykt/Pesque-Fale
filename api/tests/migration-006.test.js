// Mesmo padrão de migration-005.test.js: sem Postgres real na suíte,
// valida a estrutura do SQL. A aplicação real é feita com `npm run migrate`.
const fs = require('fs');
const path = require('path');

const sql = fs.readFileSync(
  path.join(__dirname, '..', 'db', 'migrations', '006_seed_pontos.sql'),
  'utf8'
);

// Só os comandos: comentários (-- …) podem citar qualquer coisa.
const comandos = sql
  .split('\n')
  .filter((linha) => !linha.trim().startsWith('--'))
  .join('\n');

const CONTA_OFICIAL = '69397c7f-3249-451c-98b4-6fb7dda07e3e';
const TIPOS_VALIDOS = ['pesqueiro', 'rio', 'lago', 'represa', 'mar'];

// ('<id>', '<nome>', '<descricao>', lat, lng, '<cidade>', '<UF>', '<tipo>', '<criado_por>')
const LINHA_PONTO =
  /\(\s*'([0-9a-f-]{36})',\s*'((?:[^']|'')+)',\s*'((?:[^']|'')+)',\s*(-?\d+\.\d+),\s*(-?\d+\.\d+),\s*'((?:[^']|'')+)',\s*'([A-Z]{2})',\s*'([a-z]+)',\s*'([0-9a-f-]{36})'\s*\)/g;

const pontos = [...comandos.matchAll(LINHA_PONTO)].map((m) => ({
  id: m[1],
  nome: m[2],
  latitude: Number(m[4]),
  longitude: Number(m[5]),
  estado: m[7],
  tipo: m[8],
  criadoPor: m[9],
}));

describe('migration 006_seed_pontos.sql', () => {
  it('cria a conta oficial com UUID fixo', () => {
    expect(comandos).toMatch(/INSERT INTO usuarios/);
    expect(comandos).toContain(`'${CONTA_OFICIAL}'`);
    expect(comandos).toContain("'oficial@pesqueefale.app'");
  });

  it('a conta oficial não tem hash bcrypt válido (ninguém faz login nela)', () => {
    expect(comandos).toContain("'!conta-oficial-sem-login'");
    expect(comandos).not.toMatch(/'\$2[aby]\$/);
  });

  it('todo INSERT é idempotente com ON CONFLICT (id) DO NOTHING', () => {
    const inserts = comandos.match(/INSERT INTO/g) || [];
    const conflitos = comandos.match(/ON CONFLICT \(id\) DO NOTHING/g) || [];
    expect(inserts).toHaveLength(2);
    expect(conflitos).toHaveLength(inserts.length);
  });

  it('insere 10 pontos: 5 pesqueiros e 5 em rios ou represas', () => {
    expect(pontos).toHaveLength(10);
    expect(pontos.filter((p) => p.tipo === 'pesqueiro')).toHaveLength(5);
    expect(pontos.filter((p) => ['rio', 'represa'].includes(p.tipo))).toHaveLength(5);
  });

  it('usa só tipos aceitos pelo CHECK de pontos_de_pesca.tipo', () => {
    pontos.forEach((p) => expect(TIPOS_VALIDOS).toContain(p.tipo));
  });

  it('ids únicos e todos os pontos pertencem à conta oficial', () => {
    expect(new Set(pontos.map((p) => p.id)).size).toBe(pontos.length);
    expect(pontos.map((p) => p.id)).not.toContain(CONTA_OFICIAL);
    pontos.forEach((p) => expect(p.criadoPor).toBe(CONTA_OFICIAL));
  });

  it('coordenadas caem no estado de SP, na ordem latitude, longitude', () => {
    pontos.forEach((p) => {
      expect(p.estado).toBe('SP');
      expect(p.latitude).toBeGreaterThan(-25.5);
      expect(p.latitude).toBeLessThan(-19.5);
      expect(p.longitude).toBeGreaterThan(-53.5);
      expect(p.longitude).toBeLessThan(-44);
    });
  });

  it('não abre transação própria (o npm run migrate já abre)', () => {
    expect(comandos).not.toMatch(/^\s*(BEGIN|COMMIT|ROLLBACK)\b/im);
  });

  it('não altera schema nem apaga ou atualiza dados', () => {
    expect(comandos).not.toMatch(/\b(ALTER|DROP|CREATE|DELETE|UPDATE|TRUNCATE)\b/i);
  });
});
