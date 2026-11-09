const { Router } = require('express');
const { listar, criar } = require('./comentarios.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router({ mergeParams: true });

/**
 * @swagger
 * /publicacoes/{publicacaoId}/comentarios:
 *   get:
 *     summary: Listar comentários de uma publicação
 *     tags: [Comentários]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: publicacaoId
 *         required: true
 *         schema:
 *           type: string
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
 *         description: Lista paginada de comentários com dados do autor
 *   post:
 *     summary: Criar comentário (gera notificação para o autor da publicação)
 *     tags: [Comentários]
 *     parameters:
 *       - in: path
 *         name: publicacaoId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [texto]
 *             properties:
 *               texto:
 *                 type: string
 *                 example: Que pescaria incrível!
 *     responses:
 *       201:
 *         description: Comentário criado
 *       400:
 *         description: Texto inválido (entre 1 e 500 caracteres)
 */
router.get('/', listar);
router.post('/', authMiddleware, criar);

module.exports = router;