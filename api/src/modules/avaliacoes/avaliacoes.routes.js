const { Router } = require('express');
const { criar, listar, buscarMinha, atualizar, deletar } = require('./avaliacoes.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router({ mergeParams: true });

router.get('/', listar);
router.get('/minha', authMiddleware, buscarMinha);
router.post('/', authMiddleware, criar);
router.patch('/minha', authMiddleware, atualizar);
router.delete('/minha', authMiddleware, deletar);

module.exports = router;