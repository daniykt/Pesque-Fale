const pool = require('../../config/database');
const { emitToUser } = require('../../config/socket-emitter');

async function criarNotificacao({ para, deId, tipo, texto, postId, chatId, deVolta = false }) {
  try {
    if (para === deId) return; // não notifica a si mesmo

    const remetente = await pool.query(
      'SELECT nome, username FROM usuarios WHERE id = $1',
      [deId]
    );
    if (remetente.rows.length === 0) return;

    const { nome, username } = remetente.rows[0];

    const inserido = await pool.query(
      `INSERT INTO notificacoes (para, de_id, de, de_username, tipo, texto, post_id, chat_id, de_volta)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id`,
      [para, deId, nome, username, tipo, texto ?? null, postId ?? null, chatId ?? null, deVolta === true]
    );

    const novoId = inserido.rows[0]?.id;
    if (!novoId) return;

    // A partir daqui a notificação já está no banco. Falha em montar o payload
    // ou emitir é só log — o caller é um controller que já vai responder 2xx.
    try {
      // Mesmo SELECT do GET /notificacoes, pro payload do evento não divergir
      // do que o REST devolve.
      const completa = await pool.query(
        `SELECT n.*,
                u.foto_perfil AS de_foto,
                CASE WHEN us.seguidor_id IS NOT NULL THEN true ELSE false END AS ja_sigo_de
         FROM notificacoes n
         LEFT JOIN usuarios u ON u.id = n.de_id
         LEFT JOIN usuario_seguidores us
           ON us.seguidor_id = $1 AND us.seguido_id = n.de_id
         WHERE n.id = $2`,
        [para, novoId]
      );
      if (completa.rows.length === 0) return;

      // Shape idêntico ao _format do notificacoes.controller.js — se um mudar,
      // o outro tem que acompanhar.
      const n = completa.rows[0];
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
      console.error('[notificacoes] erro pós-insert, notificação já salva:', err);
    }
  } catch (err) {
    console.error('Erro ao criar notificação:', err);
  }
}

module.exports = { criarNotificacao };
