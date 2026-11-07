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
 *         description: >
 *           true para listar só eventos futuros ou em andamento (fim, ou início
 *           quando não há fim, a partir de agora), do mais próximo para o mais
 *           distante. Sem o parâmetro, lista todos do mais recente para o mais antigo.
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
 *                 minLength: 2
 *                 maxLength: 200
 *                 example: Campeonato de Pesca de Matão 2026
 *               descricao:
 *                 type: string
 *               dataInicio:
 *                 type: string
 *                 format: date-time
 *                 description: "ISO-8601 com fuso: Z ou offset como -03:00. É convertida e gravada em UTC; data sem fuso é recusada."
 *                 example: "2026-08-15T08:00:00Z"
 *               dataFim:
 *                 type: string
 *                 format: date-time
 *                 nullable: true
 *                 description: "ISO-8601 com fuso, como dataInicio. Igual ou posterior a dataInicio."
 *                 example: "2026-08-15T14:00:00Z"
 *               localTexto:
 *                 type: string
 *                 maxLength: 150
 *                 example: Lago Azul, Matão-SP
 *               pontoId:
 *                 type: string
 *               imagemUrl:
 *                 type: string
 *     responses:
 *       201:
 *         description: Evento criado, com o organizador (organizadorNome, organizadorUsername, organizadorFoto) como no GET
 *       400:
 *         description: VALIDATION_ERROR (título, local ou datas inválidos, ou fim antes do início)
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
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             description: >
 *               Só os campos enviados mudam, com as mesmas regras do POST. Se vier
 *               só uma das datas, ela é comparada com a outra já salva.
 *             properties:
 *               titulo:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 200
 *               descricao:
 *                 type: string
 *               dataInicio:
 *                 type: string
 *                 format: date-time
 *                 description: "ISO-8601 com fuso, gravada em UTC"
 *               dataFim:
 *                 type: string
 *                 format: date-time
 *                 nullable: true
 *                 description: "ISO-8601 com fuso, gravada em UTC; null remove o fim"
 *               localTexto:
 *                 type: string
 *                 maxLength: 150
 *               pontoId:
 *                 type: string
 *               imagemUrl:
 *                 type: string
 *     responses:
 *       200:
 *         description: Evento atualizado, com o organizador (organizadorNome, organizadorUsername, organizadorFoto) como no GET
 *       400:
 *         description: VALIDATION_ERROR (mesmas regras do POST)
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