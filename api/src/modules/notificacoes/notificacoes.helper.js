const pool = require('../../config/database');
const { emitToUser } = require('../../config/socket-emitter');

// Uma ida ao banco: o INSERT pega nome e username do remetente na própria
// tabela de usuários, e o SELECT de fora devolve a linha com as mesmas colunas
// do GET /notificacoes (de_foto, ja_sigo_de). Se o remetente não existir, o
// INSERT ... SELECT não insere nada e não volta linha.
const SQL_CRIAR_NOTIFICACAO = `
  WITH ins AS (
    INSERT INTO notificacoes (para, de_id, de, de_username, tipo, texto, post_id, chat_id, de_volta)
    SELECT $1, u.id, u.nome, u.username, $3, $4, $5, $6, $7
    FROM usuarios u WHERE u.id = $2
    RETURNING *
  )
  SELECT ins.*,
         u.foto_perfil AS de_foto,
         EXISTS (SELECT 1 FROM usuario_seguidores us
                 WHERE us.seguidor_id = $1 AND us.seguido_id = ins.de_id) AS ja_sigo_de
  FROM ins
  LEFT JOIN usuarios u ON u.id = ins.de_id`;

async function criarNotificacao({ para, deId, tipo, texto, postId, chatId, deVolta = false }) {
  try {
    if (para === deId) return; // não notifica a si mesmo

    const result = await pool.query(SQL_CRIAR_NOTIFICACAO, [
      para, deId, tipo, texto ?? null, postId ?? null, chatId ?? null, deVolta === true,
    ]);
    if (result.rows.length === 0) return; // remetente não existe

    // Shape idêntico ao _format do notificacoes.controller.js — se um mudar,
    // o outro tem que acompanhar.
    const n = result.rows[0];
    emitToUser(para, 'nova_notificacao', {
      id: n.id,
      para: n.para,
      deId: n.de_id,
      de: n.de,
      deUsername: n.de_username,
      deFoto: n.de_foto,
      jaSigoDe: n.ja_sigo_de,
      deVolta: n.de_volta === true,
      tipo: n.tipo,
      texto: n.texto,
      postId: n.post_id,
      chatId: n.chat_id,
      lida: n.lida,
      criadoEm: n.criado_em,
    });
  } catch (err) {
    // Nunca lança: o caller é um controller que já vai responder 2xx.
    console.error('Erro ao criar notificação:', err);
  }
}

module.exports = { criarNotificacao };
