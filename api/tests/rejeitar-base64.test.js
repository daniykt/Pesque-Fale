process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));

const request = require('supertest');
const pool = require('../src/config/database');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const BASE64_CRU = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
const DATA_URI = `data:image/png;base64,${BASE64_CRU}`;

const publicacaoMock = {
  id: 'pub-1',
  autor_id: 'user-1',
  ponto_id: null,
  descricao: 'Primeira pescaria',
  imagem_url: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
  local_texto: 'Represa',
  avaliacao_nota: null,
  tags: [],
  curtidas_count: 0,
  comentarios_count: 0,
  criado_em: '2026-01-01T00:00:00.000Z',
  atualizado_em: '2026-01-01T00:00:00.000Z',
};

describe('Rejeição de imagem em base64 no corpo JSON', () => {
  beforeEach(() => {
    pool.query.mockReset();
  });

  it('POST /v1/publicacoes com imagem_base64 responde 400 e não toca no banco', async () => {
    const res = await request(app)
      .post('/v1/publicacoes')
      .set('Authorization', `Bearer ${gerarToken()}`)
      .send({ descricao: 'teste', imagem_base64: BASE64_CRU });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('BASE64_NAO_PERMITIDO');
    expect(res.body.details[0].campo).toBe('imagem_base64');
    expect(res.body.details[0].mensagem).toBe(
      'Campo não permitido. Envie a imagem via multipart/form-data.'
    );
    expect(pool.query).not.toHaveBeenCalled();
  });

  it('POST /v1/publicacoes com imagemBase64 em camelCase responde 400', async () => {
    const res = await request(app)
      .post('/v1/publicacoes')
      .set('Authorization', `Bearer ${gerarToken()}`)
      .send({ descricao: 'teste', imagemBase64: BASE64_CRU });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('BASE64_NAO_PERMITIDO');
    expect(res.body.details[0].campo).toBe('imagemBase64');
    expect(pool.query).not.toHaveBeenCalled();
  });

  it('POST /v1/publicacoes com data URI dentro de imagemUrl responde 400', async () => {
    const res = await request(app)
      .post('/v1/publicacoes')
      .set('Authorization', `Bearer ${gerarToken()}`)
      .send({ descricao: 'teste', imagemUrl: DATA_URI });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('BASE64_NAO_PERMITIDO');
    expect(res.body.details[0].campo).toBe('imagemUrl');
    expect(pool.query).not.toHaveBeenCalled();
  });

  it('data URI escondido em descricao responde 400 apontando o campo descricao', async () => {
    const res = await request(app)
      .post('/v1/publicacoes')
      .set('Authorization', `Bearer ${gerarToken()}`)
      .send({ descricao: DATA_URI });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('BASE64_NAO_PERMITIDO');
    expect(res.body.details[0].campo).toBe('descricao');
    expect(pool.query).not.toHaveBeenCalled();
  });

  it('POST /v1/publicacoes com corpo legítimo continua criando a publicação', async () => {
    pool.query.mockResolvedValueOnce({ rows: [publicacaoMock] });

    const res = await request(app)
      .post('/v1/publicacoes')
      .set('Authorization', `Bearer ${gerarToken()}`)
      .send({
        descricao: 'Primeira pescaria',
        imagemUrl: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        localTexto: 'Represa',
      });

    expect(res.status).toBe(201);
    expect(res.body.data.id).toBe('pub-1');
    expect(res.body.data.imagemUrl).toBe(
      'https://res.cloudinary.com/demo/image/upload/sample.jpg'
    );
    expect(pool.query).toHaveBeenCalledTimes(1);
  });

  it('rejeita base64 antes da autenticação: sem token responde 400, não 401', async () => {
    const res = await request(app)
      .post('/v1/publicacoes')
      .send({ descricao: 'teste', imagem_base64: BASE64_CRU });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('BASE64_NAO_PERMITIDO');
    expect(res.body.details[0].campo).toBe('imagem_base64');
    expect(pool.query).not.toHaveBeenCalled();
  });

  it('a regra é global: POST /v1/auth/cadastro com foto_base64 responde 400', async () => {
    const res = await request(app).post('/v1/auth/cadastro').send({
      nome: 'Fulano',
      email: 'fulano@teste.com',
      senha: '123456',
      confirmarSenha: '123456',
      foto_base64: BASE64_CRU,
    });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('BASE64_NAO_PERMITIDO');
    expect(res.body.details[0].campo).toBe('foto_base64');
    expect(pool.query).not.toHaveBeenCalled();
  });
});
