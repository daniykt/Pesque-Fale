const multer = require('multer');

const TAMANHO_MAXIMO = 5 * 1024 * 1024; // 5MB

const MIME_PERMITIDOS = ['image/jpeg', 'image/png', 'image/webp'];

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: TAMANHO_MAXIMO },
  fileFilter: (_req, file, cb) => {
    if (MIME_PERMITIDOS.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('FORMATO_INVALIDO'));
    }
  },
});

module.exports = upload;