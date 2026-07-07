const { Router } = require('express');
const { criar, listar, buscarPorId, atualizar, deletar } = require('./pontos.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router();

router.get('/', listar);
router.get('/:id', buscarPorId);
router.post('/', authMiddleware, criar);
router.patch('/:id', authMiddleware, atualizar);
router.delete('/:id', authMiddleware, deletar);

module.exports = router;