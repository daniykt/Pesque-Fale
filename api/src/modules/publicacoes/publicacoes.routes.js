const { Router } = require('express');
const { listarPorUsuario, criar, buscarPorId, deletar } = require('./publicacoes.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router();

router.get('/:id', buscarPorId);
router.delete('/:id', authMiddleware, deletar);
router.post('/', authMiddleware, criar);

module.exports = router;