process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const token = gerarToken('user-1');

function linhaUsuario({ onboardingConcluido = false, nome = 'Fulano' } = {}) {
  return {
    id: 'user-1',
    nome,
    email: 'fulano@teste.com',
    username: 'fulano',
    foto_perfil: null,
    banner: null,
    bio: '',
    localizacao: '',
    onboarding_concluido: onboardingConcluido,
    criado_em: '2026-01-01T00:00:00.000Z',
  };
}

/**
 * updateMe roda o UPDATE e depois duas contagens de seguidores/seguindo.
 * Essa ordem precisa ser respeitada nos mocks.
 */
function mockUpdateRetornando(linha) {
  pool.query
    .mockResolvedValueOnce({ rows: [linha] })
    .mockResolvedValueOnce({ rows: [{ count: '0' }] })
    .mockResolvedValueOnce({ rows: [{ count: '0' }] });
}

function chamadaUpdate() {
  return pool.query.mock.calls.find(([sql]) => sql.includes('UPDATE usuarios SET'));
}

describe('PATCH /v1/usuarios/me — onboardingConcluido', () => {
  beforeEach(() => {
    pool.query.mockReset();
  });

  it('com onboardingConcluido: true persiste a coluna e retorna true', async () => {
    mockUpdateRetornando(linhaUsuario({ onboardingConcluido: true }));

    const res = await request(app)
      .patch('/v1/usuarios/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ onboardingConcluido: true });

    expect(res.status).toBe(200);
    expect(res.body.data.onboardingConcluido).toBe(true);

    const [sql, valores] = chamadaUpdate();
    expect(sql).toContain('onboarding_concluido =');
    expect(valores).toContain(true);
  });

  it('com onboardingConcluido: false ignora o campo e não altera a coluna', async () => {
    mockUpdateRetornando(linhaUsuario({ onboardingConcluido: false, nome: 'Novo Nome' }));

    const res = await request(app)
      .patch('/v1/usuarios/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ nome: 'Novo Nome', onboardingConcluido: false });

    expect(res.status).toBe(200);
    expect(res.body.data.onboardingConcluido).toBe(false);

    const [sql, valores] = chamadaUpdate();
    expect(sql).not.toContain('onboarding_concluido =');
    expect(valores).not.toContain(false);
  });

  it('com onboardingConcluido: false como único campo responde 400 (nada a atualizar)', async () => {
    const res = await request(app)
      .patch('/v1/usuarios/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ onboardingConcluido: false });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('VALIDATION_ERROR');
    expect(chamadaUpdate()).toBeUndefined();
  });

  it('sem o campo mantém o comportamento atual dos outros campos', async () => {
    mockUpdateRetornando(linhaUsuario({ nome: 'Fulano Editado' }));

    const res = await request(app)
      .patch('/v1/usuarios/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ nome: 'Fulano Editado', bio: 'Pescador de fim de semana' });

    expect(res.status).toBe(200);
    expect(res.body.data.nome).toBe('Fulano Editado');
    expect(res.body.data.onboardingConcluido).toBe(false);

    const [sql, valores] = chamadaUpdate();
    expect(sql).toContain('nome =');
    expect(sql).toContain('bio =');
    expect(sql).not.toContain('onboarding_concluido =');
    expect(valores).toEqual(['Fulano Editado', 'Pescador de fim de semana', 'user-1']);
  });
});
