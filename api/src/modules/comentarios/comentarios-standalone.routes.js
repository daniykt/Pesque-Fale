const { Router } = require('express');
const { deletar } = require('./comentarios.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router();

/**
 * @swagger
 * /comentarios/{id}:
 *   delete:
 *     summary: Deletar comentário (só o autor)
 *     tags: [Comentários]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       204:
 *         description: Comentário deletado
 *       403:
 *         description: Sem permissão
 *       404:
 *         description: Comentário não encontrado
 */
router.delete('/:id', authMiddleware, deletar);

module.exports = router;