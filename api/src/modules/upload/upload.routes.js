const { Router } = require('express');
const upload = require('../../config/multer');
const authMiddleware = require('../../middlewares/auth.middleware');
const { uploadFoto, uploadBanner } = require('./upload.controller');

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

router.post(
  '/me/foto',
  authMiddleware,
  upload.single('foto'),
  handleMulterError,
  uploadFoto
);

router.post(
  '/me/banner',
  authMiddleware,
  upload.single('banner'),
  handleMulterError,
  uploadBanner
);

module.exports = router;