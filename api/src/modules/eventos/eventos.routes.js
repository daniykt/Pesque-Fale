const { Router } = require('express');
const { criar, listar, buscarPorId, atualizar, deletar } = require('./eventos.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router();

/**
 * @swagger
 * /eventos:
 *   get:
 *     summary: Listar eventos
 *     tags: [Eventos]
 *     security: []
 *     parameters:
 *       - in: query
 *         name: futuros
 *         schema:
 *           type: boolean
 *         description: true para listar apenas eventos futuros
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
 *         description: Lista paginada de eventos com dados do organizador
 *   post:
 *     summary: Criar evento
 *     tags: [Eventos]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [titulo, dataInicio]
 *             properties:
 *               titulo:
 *                 type: string
 *                 example: Campeonato de Pesca de Matão 2026
 *               descricao:
 *                 type: string
 *               dataInicio:
 *                 type: string
 *                 format: date-time
 *                 example: "2026-08-15T08:00:00Z"
 *               dataFim:
 *                 type: string
 *                 format: date-time
 *               localTexto:
 *                 type: string
 *                 example: Lago Azul, Matão-SP
 *               pontoId:
 *                 type: string
 *               imagemUrl:
 *                 type: string
 *     responses:
 *       201:
 *         description: Evento criado
 */
router.get('/', listar);
router.post('/', authMiddleware, criar);

/**
 * @swagger
 * /eventos/{id}:
 *   get:
 *     summary: Buscar evento por ID
 *     tags: [Eventos]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Evento encontrado
 *       404:
 *         description: Evento não encontrado
 *   patch:
 *     summary: Editar evento (só o organizador)
 *     tags: [Eventos]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Evento atualizado
 *       403:
 *         description: Sem permissão
 *   delete:
 *     summary: Deletar evento (só o organizador)
 *     tags: [Eventos]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       204:
 *         description: Evento deletado
 *       403:
 *         description: Sem permissão
 */
router.get('/:id', buscarPorId);
router.patch('/:id', authMiddleware, atualizar);
router.delete('/:id', authMiddleware, deletar);

module.exports = router;