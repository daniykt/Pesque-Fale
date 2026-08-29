const { Router } = require('express');
const { curtir, descurtir } = require('./curtidas.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router({ mergeParams: true });

/**
 * @swagger
 * /publicacoes/{publicacaoId}/curtir:
 *   post:
 *     summary: Curtir publicação (gera notificação para o autor)
 *     tags: [Curtidas]
 *     parameters:
 *       - in: path
 *         name: publicacaoId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       201:
 *         description: '{ "data": { "curtido": true } }'
 *       404:
 *         description: Publicação não encontrada
 *   delete:
 *     summary: Descurtir publicação
 *     tags: [Curtidas]
 *     parameters:
 *       - in: path
 *         name: publicacaoId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: '{ "data": { "curtido": false } }'
 */
router.post('/', authMiddleware, curtir);
router.delete('/', authMiddleware, descurtir);

module.exports = router;