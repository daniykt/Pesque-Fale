const { Router } = require('express');
const {
  getPerfil, getMe, updateMe, checkUsername,
  seguir, deixarDeSeguir, getSeguidores, getSeguindo, buscar
} = require('./usuarios.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const { listarPorUsuario } = require('../publicacoes/publicacoes.controller');

const router = Router();

router.get('/me', authMiddleware, getMe);
router.patch('/me', authMiddleware, updateMe);
router.get('/username/:username', checkUsername);
router.get('/:id/seguidores', getSeguidores);
router.get('/:id/seguindo', getSeguindo);
router.get('/:id/publicacoes', listarPorUsuario);
router.get('/', buscar);
router.get('/:id', getPerfil);
router.post('/:id/seguir', authMiddleware, seguir);
router.delete('/:id/seguir', authMiddleware, deixarDeSeguir);

module.exports = router;