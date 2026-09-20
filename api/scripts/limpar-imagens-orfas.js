/**
 * Script pontual (one-shot) — limpeza das URLs de imagem orfas. Refs: #114.
 *
 * Por que existe:
 * O upload de foto de perfil e banner chamava `cloudinary.uploader.destroy()`
 * sobre o mesmo `public_id` que acabara de subir. Como o `public_id` e
 * deterministico por usuario e o upload usa `overwrite: true`, o primeiro
 * envio sobrevivia e todos os seguintes se autodestruiam. O resultado e que
 * os assets em `fotos_perfil/` e `banners/` foram apagados do Cloudinary,
 * enquanto as colunas `usuarios.foto_perfil` e `usuarios.banner` continuam
 * apontando para essas URLs — que hoje respondem 404.
 *
 * Corrigir o codigo (commit do fix) nao ressuscita as imagens. Enquanto as
 * colunas tiverem URL, o app tenta renderizar e cai no placeholder de erro.
 * Zerando as duas colunas, o app volta a exibir o fallback visual normal
 * (inicial do nome no avatar, gradiente no banner) ate o usuario reenviar.
 *
 * Executar UMA VEZ, apos o deploy do fix:
 *   node scripts/limpar-imagens-orfas.js
 */

const pool = require('../src/config/database');

async function main() {
  console.log('Limpando URLs de imagens orfas (#114)...');

  const { rows } = await pool.query(
    `SELECT
       COUNT(*) FILTER (WHERE foto_perfil IS NOT NULL) AS fotos,
       COUNT(*) FILTER (WHERE banner IS NOT NULL) AS banners
     FROM usuarios`
  );
  console.log(`  antes: ${rows[0].fotos} foto(s) de perfil, ${rows[0].banners} banner(s)`);

  const resultado = await pool.query(
    `UPDATE usuarios
        SET foto_perfil = NULL,
            banner = NULL,
            atualizado_em = NOW()
      WHERE foto_perfil IS NOT NULL
         OR banner IS NOT NULL`
  );

  console.log(`  ${resultado.rowCount} linha(s) afetada(s).`);
  console.log('Concluido. Os usuarios voltam a ver o fallback ate reenviarem as imagens.');
}

main()
  .catch((err) => {
    console.error('Falha ao limpar imagens orfas:', err.message);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
