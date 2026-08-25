const { Router } = require('express');
const { listarPorUsuario, listar, criar, buscarPorId, deletar } = require('./publicacoes.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const authOpcional = require('../../middlewares/auth-opcional.middleware');

const router = Router();

router.get('/', authOpcional, listar);
router.get('/:id', buscarPorId);
router.delete('/:id', authMiddleware, deletar);
router.post('/', authMiddleware, criar);

module.exports = router;