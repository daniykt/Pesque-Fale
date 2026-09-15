const cloudinary = require('cloudinary').v2;
require('dotenv').config();

const PLACEHOLDER_PREFIXES = ['seu_', 'sua_'];
const VARS = ['CLOUDINARY_CLOUD_NAME', 'CLOUDINARY_API_KEY', 'CLOUDINARY_API_SECRET'];

const invalidas = VARS.filter((k) => {
  const v = process.env[k];
  if (!v) return true;
  return PLACEHOLDER_PREFIXES.some((p) => v.startsWith(p));
});

if (invalidas.length > 0) {
  console.warn(
    `⚠️  [Cloudinary] Variáveis não configuradas ou com valor placeholder: ${invalidas.join(', ')}\n` +
    `   Uploads de foto/banner vão falhar com 500. Configure no api/.env.`
  );
}

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

module.exports = cloudinary;