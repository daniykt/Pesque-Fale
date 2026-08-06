const { Router } = require('express');
const { listar, criar } = require('./comentarios.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router({ mergeParams: true });

router.get('/', listar);
router.post('/', authMiddleware, criar);

module.exports = router;
