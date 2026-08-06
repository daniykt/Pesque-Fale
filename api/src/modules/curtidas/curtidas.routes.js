const { Router } = require('express');
const { curtir, descurtir } = require('./curtidas.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

const router = Router({ mergeParams: true });

router.post('/', authMiddleware, curtir);
router.delete('/', authMiddleware, descurtir);

module.exports = router;
