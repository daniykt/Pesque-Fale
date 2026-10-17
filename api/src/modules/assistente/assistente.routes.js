const { Router } = require('express');
const { conversar } = require('./assistente.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router();

/**
 * @swagger
 * /assistente:
 *   post:
 *     summary: Conversar com o assistente virtual do app
 *     tags: [Assistente]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [mensagem]
 *             properties:
 *               mensagem:
 *                 type: string
 *                 maxLength: 500
 *                 example: Como publico uma pescaria?
 *               historico:
 *                 type: array
 *                 description: Últimas mensagens da conversa (só as 6 mais recentes são usadas)
 *                 items:
 *                   type: object
 *                   properties:
 *                     papel:
 *                       type: string
 *                       enum: [usuario, assistente]
 *                     texto:
 *                       type: string
 *               tela:
 *                 type: string
 *                 description: Tela em que o usuário está
 *                 example: inicio
 *     responses:
 *       200:
 *         description: '{ "data": { "resposta": "...", "acoes": [] } }'
 *       400:
 *         description: Dados inválidos
 *       401:
 *         description: Sem token
 *       429:
 *         description: Limite de perguntas por hora atingido
 *       503:
 *         description: Assistente indisponível (sem chave configurada ou falha da IA)
 */
router.post('/', authMiddleware, conversar);

module.exports = router;