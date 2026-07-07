const cloudinary = require('../../config/cloudinary');
const pool = require('../../config/database');

// Magic bytes para detectar formato real do arquivo
function detectarMimeReal(buffer) {
  if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) return 'image/jpeg';
  if (buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47) return 'image/png';
  if (buffer[0] === 0x52 && buffer[1] === 0x49 && buffer[2] === 0x46 && buffer[3] === 0x46) return 'image/webp';
  return null;
}

const MIME_PERMITIDOS = ['image/jpeg', 'image/png', 'image/webp'];

async function uploadFoto(req, res) {
  return _upload(req, res, 'foto');
}

async function uploadBanner(req, res) {
  return _upload(req, res, 'banner');
}

async function _upload(req, res, tipo) {
  if (!req.file) {
    return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Nenhum arquivo enviado.' });
  }

  const mimeReal = detectarMimeReal(req.file.buffer);
  if (!mimeReal || !MIME_PERMITIDOS.includes(mimeReal)) {
    return res.status(415).json({ error: 'FORMATO_INVALIDO', message: 'Formato inválido. Use jpeg, png ou webp.' });
  }

  const usuarioId = req.usuario.id;

  try {
    // Busca URL antiga para deletar do Cloudinary
    const campo = tipo === 'foto' ? 'foto_perfil' : 'banner';
    const atual = await pool.query(`SELECT ${campo} FROM usuarios WHERE id = $1`, [usuarioId]);
    const urlAntiga = atual.rows[0]?.[campo];

    // Faz upload para o Cloudinary
    const pasta = tipo === 'foto' ? 'fotos_perfil' : 'banners';
    const publicId = `${pasta}/${usuarioId}`;

    const resultado = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          folder: pasta,
          public_id: usuarioId,
          overwrite: true,
          resource_type: 'image',
          transformation: tipo === 'foto'
            ? [{ width: 400, height: 400, crop: 'fill', gravity: 'face' }]
            : [{ width: 1200, height: 400, crop: 'fill' }],
        },
        (error, result) => {
          if (error) reject(error);
          else resolve(result);
        }
      );
      stream.end(req.file.buffer);
    });

    const novaUrl = resultado.secure_url;

    // Deleta imagem antiga se existir e for diferente
    if (urlAntiga && urlAntiga !== novaUrl) {
      try {
        await cloudinary.uploader.destroy(publicId);
      } catch {
        // Falha silenciosa — não bloqueia o upload
      }
    }

    // Persiste a nova URL no banco
    await pool.query(
      `UPDATE usuarios SET ${campo} = $1, atualizado_em = NOW() WHERE id = $2`,
      [novaUrl, usuarioId]
    );

    const resposta = tipo === 'foto'
      ? { fotoPerfil: novaUrl }
      : { banner: novaUrl };

    return res.json({ data: resposta });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Erro interno no servidor.' });
  }
}

module.exports = { uploadFoto, uploadBanner };