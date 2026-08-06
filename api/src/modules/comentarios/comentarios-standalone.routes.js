const { Router } = require('express');
const { deletar } = require('./comentarios.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router();

router.delete('/:id', authMiddleware, deletar);

module.exports = router;
