const { Router } = require('express');
const upload = require('../../config/multer');
const authMiddleware = require('../../middlewares/auth.middleware');
const { uploadFoto, uploadBanner, uploadImagemPublicacao } = require('./upload.controller');

const router = Router();

function handleMulterError(err, req, res, next) {
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({
      error: 'ARQUIVO_MUITO_GRANDE',
      message: 'O arquivo deve ter no máximo 5MB.',
    });
  }
  if (err.message === 'FORMATO_INVALIDO') {
    return res.status(415).json({
      error: 'FORMATO_INVALIDO',
      message: 'Formato inválido. Use jpeg, png ou webp.',
    });
  }
  next(err);
}

/**
 * @swagger
 * /usuarios/me/foto:
 *   post:
 *     summary: Upload de foto de perfil (crop 400x400 face)
 *     tags: [Upload]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               foto:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: '{ "data": { "fotoPerfil": "https://res.cloudinary.com/..." } }'
 *       413:
 *         description: Arquivo maior que 5MB
 *       415:
 *         description: Formato inválido
 */
router.post(
  '/me/foto',
  authMiddleware,
  upload.single('foto'),
  handleMulterError,
  uploadFoto
);

/**
 * @swagger
 * /usuarios/me/banner:
 *   post:
 *     summary: Upload de banner do perfil (crop 1200x400)
 *     tags: [Upload]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               banner:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: '{ "data": { "banner": "https://res.cloudinary.com/..." } }'
 *       413:
 *         description: Arquivo maior que 5MB
 *       415:
 *         description: Formato inválido
 */
router.post(
  '/me/banner',
  authMiddleware,
  upload.single('banner'),
  handleMulterError,
  uploadBanner
);

/**
 * @swagger
 * /publicacoes/imagens:
 *   post:
 *     summary: Upload de imagem de publicação (limit 1200x1200)
 *     tags: [Upload]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               imagem:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: '{ "data": { "imagemUrl": "https://res.cloudinary.com/..." } }'
 *       413:
 *         description: Arquivo maior que 5MB
 *       415:
 *         description: Formato inválido
 */
router.post(
  '/imagens',
  authMiddleware,
  upload.single('imagem'),
  handleMulterError,
  uploadImagemPublicacao
);

module.exports = router;