process.env.JWT_SECRET = 'test_secret';
process.env.JWT_EXPIRES_IN = '24h';

jest.mock('../src/config/database', () => ({ query: jest.fn() }));
jest.mock('../src/config/cloudinary', () => ({
  uploader: { upload_stream: jest.fn(), destroy: jest.fn() },
}));

const request = require('supertest');
const pool = require('../src/config/database');
const cloudinary = require('../src/config/cloudinary');
const app = require('../src/app');
const { gerarToken } = require('./helpers/token');

const token = gerarToken('user-1');

/** JPEG real o suficiente para passar pelo detectarMimeReal (magic FF D8 FF). */
function bufferJpeg() {
  return Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(64, 7)]);
}

/**
 * O controller faz `upload_stream(opts, cb)` e depois `stream.end(buffer)`.
 * O mock devolve esse shape e dispara o callback com um resultado do SDK.
 */
function mockCloudinaryRetornando(secureUrl) {
  cloudinary.uploader.upload_stream.mockImplementation((_opts, cb) => ({
    end: () => cb(null, { secure_url: secureUrl }),
  }));
}

function opcoesDoUpload(chamada = 0) {
  return cloudinary.uploader.upload_stream.mock.calls[chamada][0];
}

function enviar(rota, campo) {
  return request(app)
    .post(rota)
    .set('Authorization', `Bearer ${token}`)
    .attach(campo, bufferJpeg(), { filename: 'imagem.jpg', contentType: 'image/jpeg' });
}

const URL_FOTO = 'https://res.cloudinary.com/demo/image/upload/v1/fotos_perfil/user-1.jpg';
const URL_BANNER = 'https://res.cloudinary.com/demo/image/upload/v1/banners/user-1.jpg';

// Usuario que JA possui imagens. E esse o cenario em que o bug do #114
// disparava: com a coluna preenchida, a versao nova sempre diferia da antiga
// e o destroy era acionado sobre o asset recem-criado. Se o mock devolvesse
// `rows: []` o teste passaria ate com o codigo bugado.
const URL_ANTIGA_FOTO = 'https://res.cloudinary.com/demo/image/upload/v0/fotos_perfil/user-1.jpg';
const URL_ANTIGA_BANNER = 'https://res.cloudinary.com/demo/image/upload/v0/banners/user-1.jpg';

describe('POST /v1/usuarios/me/foto e /banner', () => {
  beforeEach(() => {
    pool.query.mockReset();
    cloudinary.uploader.upload_stream.mockReset();
    cloudinary.uploader.destroy.mockReset();
    pool.query.mockResolvedValue({
      rows: [{ foto_perfil: URL_ANTIGA_FOTO, banner: URL_ANTIGA_BANNER }],
    });
  });

  describe('foto de perfil', () => {
    it('chama upload_stream com folder, public_id, overwrite e transformation corretos', async () => {
      mockCloudinaryRetornando(URL_FOTO);

      const res = await enviar('/v1/usuarios/me/foto', 'foto');

      expect(res.status).toBe(200);
      expect(opcoesDoUpload()).toMatchObject({
        folder: 'fotos_perfil',
        public_id: 'user-1',
        overwrite: true,
        resource_type: 'image',
        transformation: [{ width: 400, height: 400, crop: 'fill', gravity: 'face' }],
      });
    });

    it('responde 200 com data.fotoPerfil vindo do secure_url do SDK', async () => {
      mockCloudinaryRetornando(URL_FOTO);

      const res = await enviar('/v1/usuarios/me/foto', 'foto');

      expect(res.status).toBe(200);
      expect(res.body.data.fotoPerfil).toBe(URL_FOTO);
    });

    it('persiste o secure_url na coluna foto_perfil', async () => {
      mockCloudinaryRetornando(URL_FOTO);

      await enviar('/v1/usuarios/me/foto', 'foto');

      const [sql, valores] = pool.query.mock.calls.find(([texto]) =>
        texto.includes('UPDATE usuarios SET')
      );
      expect(sql).toContain('foto_perfil =');
      expect(valores).toEqual([URL_FOTO, 'user-1']);
    });
  });

  describe('banner', () => {
    it('chama upload_stream com folder, public_id, overwrite e transformation corretos', async () => {
      mockCloudinaryRetornando(URL_BANNER);

      const res = await enviar('/v1/usuarios/me/banner', 'banner');

      expect(res.status).toBe(200);
      expect(opcoesDoUpload()).toMatchObject({
        folder: 'banners',
        public_id: 'user-1',
        overwrite: true,
        resource_type: 'image',
        transformation: [{ width: 1200, height: 400, crop: 'fill' }],
      });
    });

    it('responde 200 com data.banner vindo do secure_url do SDK', async () => {
      mockCloudinaryRetornando(URL_BANNER);

      const res = await enviar('/v1/usuarios/me/banner', 'banner');

      expect(res.status).toBe(200);
      expect(res.body.data.banner).toBe(URL_BANNER);
    });

    it('persiste o secure_url na coluna banner', async () => {
      mockCloudinaryRetornando(URL_BANNER);

      await enviar('/v1/usuarios/me/banner', 'banner');

      const [sql, valores] = pool.query.mock.calls.find(([texto]) =>
        texto.includes('UPDATE usuarios SET')
      );
      expect(sql).toContain('banner =');
      expect(valores).toEqual([URL_BANNER, 'user-1']);
    });
  });

  /**
   * Regressao do #114: o controller chamava destroy() no mesmo public_id que
   * acabara de subir. Como o public_id e deterministico por usuario e o upload
   * usa overwrite: true, o primeiro envio sobrevivia e todos os seguintes se
   * autodestruiam. destroy() nao deve ser chamado em nenhuma hipotese aqui.
   */
  describe('regressao #114 - destroy nunca e chamado', () => {
    it('nao chama destroy no upload de foto', async () => {
      mockCloudinaryRetornando(URL_FOTO);

      await enviar('/v1/usuarios/me/foto', 'foto');

      expect(cloudinary.uploader.destroy).not.toHaveBeenCalled();
    });

    it('nao chama destroy no upload de banner', async () => {
      mockCloudinaryRetornando(URL_BANNER);

      await enviar('/v1/usuarios/me/banner', 'banner');

      expect(cloudinary.uploader.destroy).not.toHaveBeenCalled();
    });

    it('dois uploads consecutivos do mesmo usuario respondem 200 sem destruir o asset', async () => {
      const primeira = 'https://res.cloudinary.com/demo/image/upload/v1/fotos_perfil/user-1.jpg';
      const segunda = 'https://res.cloudinary.com/demo/image/upload/v2/fotos_perfil/user-1.jpg';

      mockCloudinaryRetornando(primeira);
      const res1 = await enviar('/v1/usuarios/me/foto', 'foto');

      // segundo envio: e aqui que o bug disparava, porque ja havia url antiga
      mockCloudinaryRetornando(segunda);
      const res2 = await enviar('/v1/usuarios/me/foto', 'foto');

      expect(res1.status).toBe(200);
      expect(res2.status).toBe(200);
      expect(res1.body.data.fotoPerfil).toBe(primeira);
      expect(res2.body.data.fotoPerfil).toBe(segunda);
      expect(cloudinary.uploader.destroy).not.toHaveBeenCalled();
      expect(cloudinary.uploader.upload_stream).toHaveBeenCalledTimes(2);
    });
  });
});
