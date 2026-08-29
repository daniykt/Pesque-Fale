const { Router } = require('express');
const { listar, marcarComoLida, marcarTodasComoLidas, contarNaoLidas } = require('./notificacoes.controller');
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
 *         description: Lista paginada de notificações com deFoto e jaSigoDe
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

module.exports = router;