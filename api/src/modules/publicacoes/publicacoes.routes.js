const { Router } = require('express');
const { listarPorUsuario, listar, criar, buscarPorId, deletar } = require('./publicacoes.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const authOpcional = require('../../middlewares/auth-opcional.middleware');

const router = Router();

/**
 * @swagger
 * /publicacoes:
 *   get:
 *     summary: Feed de publicações
 *     tags: [Publicações]
 *     security: []
 *     parameters:
 *       - in: query
 *         name: seguindo
 *         schema:
 *           type: boolean
 *         description: true para ver só publicações de quem você segue
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
 *         description: Lista paginada de publicações
 */
router.get('/', authOpcional, listar);

/**
 * @swagger
 * /publicacoes/{id}:
 *   get:
 *     summary: Buscar publicação por ID
 *     tags: [Publicações]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Publicação encontrada
 *       404:
 *         description: Publicação não encontrada
 *   delete:
 *     summary: Deletar publicação (só o autor)
 *     tags: [Publicações]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       204:
 *         description: Publicação deletada
 *       403:
 *         description: Sem permissão
 */
router.get('/:id', buscarPorId);
router.delete('/:id', authMiddleware, deletar);

/**
 * @swagger
 * /publicacoes:
 *   post:
 *     summary: Criar publicação
 *     tags: [Publicações]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               descricao:
 *                 type: string
 *                 example: Pescaria incrível hoje!
 *               imagemUrl:
 *                 type: string
 *                 example: https://res.cloudinary.com/...
 *               localTexto:
 *                 type: string
 *                 example: Lago Azul, Matão-SP
 *               avaliacaoNota:
 *                 type: number
 *                 example: 4.5
 *               pontoId:
 *                 type: string
 *                 example: uuid-opcional
 *               tags:
 *                 type: array
 *                 items:
 *                   type: string
 *                 example: ["tucunaré", "família"]
 *     responses:
 *       201:
 *         description: Publicação criada
 */
router.post('/', authMiddleware, criar);

module.exports = router;