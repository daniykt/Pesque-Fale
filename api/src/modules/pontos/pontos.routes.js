const { Router } = require('express');
const { criar, listar, buscarPorId, atualizar, deletar } = require('./pontos.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router();

/**
 * @swagger
 * /pontos:
 *   get:
 *     summary: Listar pontos de pesca
 *     tags: [Pontos de Pesca]
 *     security: []
 *     parameters:
 *       - in: query
 *         name: lat
 *         schema:
 *           type: number
 *         description: Latitude para busca por proximidade
 *         example: -21.6082
 *       - in: query
 *         name: lng
 *         schema:
 *           type: number
 *         description: Longitude para busca por proximidade
 *         example: -48.3658
 *       - in: query
 *         name: raio
 *         schema:
 *           type: number
 *           default: 50
 *         description: Raio em km
 *       - in: query
 *         name: tipo
 *         schema:
 *           type: string
 *           enum: [pesqueiro, rio, lago, represa, mar]
 *       - in: query
 *         name: cidade
 *         schema:
 *           type: string
 *       - in: query
 *         name: busca
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
 *         description: Lista paginada de pontos (com distanciaKm se lat/lng informados)
 */
router.get('/', listar);

/**
 * @swagger
 * /pontos/{id}:
 *   get:
 *     summary: Buscar ponto por ID
 *     tags: [Pontos de Pesca]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Ponto encontrado
 *       404:
 *         description: Ponto não encontrado
 *   patch:
 *     summary: Editar ponto (só o criador)
 *     tags: [Pontos de Pesca]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Ponto atualizado
 *       403:
 *         description: Sem permissão
 *   delete:
 *     summary: Deletar ponto (só o criador)
 *     tags: [Pontos de Pesca]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       204:
 *         description: Ponto deletado
 *       403:
 *         description: Sem permissão
 */
router.get('/:id', buscarPorId);
router.patch('/:id', authMiddleware, atualizar);
router.delete('/:id', authMiddleware, deletar);

/**
 * @swagger
 * /pontos:
 *   post:
 *     summary: Criar ponto de pesca
 *     tags: [Pontos de Pesca]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [nome, latitude, longitude, cidade, estado, tipo]
 *             properties:
 *               nome:
 *                 type: string
 *                 example: Lago Azul de Matão
 *               latitude:
 *                 type: number
 *                 example: -21.6082
 *               longitude:
 *                 type: number
 *                 example: -48.3658
 *               cidade:
 *                 type: string
 *                 example: Matão
 *               estado:
 *                 type: string
 *                 example: SP
 *               tipo:
 *                 type: string
 *                 enum: [pesqueiro, rio, lago, represa, mar]
 *               descricao:
 *                 type: string
 *               tags:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       201:
 *         description: Ponto criado
 */
router.post('/', authMiddleware, criar);

module.exports = router;