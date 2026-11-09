const { Router } = require('express');
const { criar, listar, buscarMinha, atualizar, deletar } = require('./avaliacoes.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router({ mergeParams: true });

/**
 * @swagger
 * /pontos/{pontoId}/avaliacoes:
 *   get:
 *     summary: Listar avaliações de um ponto
 *     tags: [Avaliações]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: pontoId
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
 *         description: Lista paginada de avaliações com dados do autor
 *   post:
 *     summary: Criar avaliação (nota 1.0 a 5.0)
 *     tags: [Avaliações]
 *     parameters:
 *       - in: path
 *         name: pontoId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [nota]
 *             properties:
 *               nota:
 *                 type: number
 *                 example: 4.5
 *               comentario:
 *                 type: string
 *                 example: Ótimo local!
 *     responses:
 *       201:
 *         description: Avaliação criada — trigger atualiza avgNota no ponto
 *       409:
 *         description: Você já avaliou este ponto
 */
router.get('/', listar);
router.post('/', authMiddleware, criar);

/**
 * @swagger
 * /pontos/{pontoId}/avaliacoes/minha:
 *   get:
 *     summary: Ver minha avaliação do ponto
 *     tags: [Avaliações]
 *     parameters:
 *       - in: path
 *         name: pontoId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Avaliação encontrada
 *       404:
 *         description: Você ainda não avaliou este ponto
 *   patch:
 *     summary: Atualizar minha avaliação
 *     tags: [Avaliações]
 *     parameters:
 *       - in: path
 *         name: pontoId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nota:
 *                 type: number
 *               comentario:
 *                 type: string
 *     responses:
 *       200:
 *         description: Avaliação atualizada
 *   delete:
 *     summary: Deletar minha avaliação
 *     tags: [Avaliações]
 *     parameters:
 *       - in: path
 *         name: pontoId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       204:
 *         description: Avaliação deletada
 */
router.get('/minha', authMiddleware, buscarMinha);
router.patch('/minha', authMiddleware, atualizar);
router.delete('/minha', authMiddleware, deletar);

module.exports = router;