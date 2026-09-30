const { Router } = require('express');
const {
  listar,
  marcarComoLida,
  marcarTodasComoLidas,
  contarNaoLidas,
  apagar,
  apagarTodas,
} = require('./notificacoes.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router();

/**
 * @swagger
 * /notificacoes:
 *   get:
 *     summary: Listar notificações do usuário autenticado
 *     tags: [Notificações]
 *     parameters:
 *       - in: query
 *         name: pagina
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: porPagina
 *         schema:
 *           type: integer
 *           default: 20
 *     responses:
 *       200:
 *         description: >-
 *           Lista paginada de notificações. Cada item traz deFoto (foto do
 *           autor), jaSigoDe (se eu sigo o autor hoje) e deVolta (true quando a
 *           notificação do tipo seguindo foi um seguir de volta).
 */
router.get('/', authMiddleware, listar);

/**
 * @swagger
 * /notificacoes/nao-lidas:
 *   get:
 *     summary: Contar notificações não lidas
 *     tags: [Notificações]
 *     responses:
 *       200:
 *         description: '{ "data": { "naoLidas": 3 } }'
 */
router.get('/nao-lidas', authMiddleware, contarNaoLidas);

/**
 * @swagger
 * /notificacoes/todas-lidas:
 *   patch:
 *     summary: Marcar todas as notificações como lidas
 *     tags: [Notificações]
 *     responses:
 *       204:
 *         description: Todas marcadas como lidas
 */
router.patch('/todas-lidas', authMiddleware, marcarTodasComoLidas);

/**
 * @swagger
 * /notificacoes/{id}/lida:
 *   patch:
 *     summary: Marcar notificação como lida
 *     tags: [Notificações]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Notificação marcada como lida
 *       404:
 *         description: Notificação não encontrada
 */
router.patch('/:id/lida', authMiddleware, marcarComoLida);

/**
 * @swagger
 * /notificacoes:
 *   delete:
 *     summary: Apagar todas as notificações do usuário autenticado
 *     tags: [Notificações]
 *     responses:
 *       204:
 *         description: Todas as notificações do usuário foram apagadas
 *       401:
 *         description: Token ausente ou inválido
 */
router.delete('/', authMiddleware, apagarTodas);

/**
 * @swagger
 * /notificacoes/{id}:
 *   delete:
 *     summary: Apagar uma notificação do usuário autenticado
 *     tags: [Notificações]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       204:
 *         description: Notificação apagada
 *       401:
 *         description: Token ausente ou inválido
 *       403:
 *         description: A notificação pertence a outro usuário
 *       404:
 *         description: Notificação não encontrada
 */
router.delete('/:id', authMiddleware, apagar);

module.exports = router;