const { Router } = require('express');
const { listar, marcarComoLida, marcarTodasComoLidas, contarNaoLidas } = require('./notificacoes.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router();

router.get('/', authMiddleware, listar);
router.get('/nao-lidas', authMiddleware, contarNaoLidas);
router.patch('/todas-lidas', authMiddleware, marcarTodasComoLidas);
router.patch('/:id/lida', authMiddleware, marcarComoLida);

module.exports = router;