const { Router } = require('express');
const { cadastro, login } = require('./auth.controller');

const router = Router();

router.post('/cadastro', cadastro);
router.post('/login', login);

module.exports = router;