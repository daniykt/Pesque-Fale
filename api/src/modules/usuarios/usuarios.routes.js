const { Router } = require('express');
const {
  getPerfil, getMe, updateMe, checkUsername,
  seguir, deixarDeSeguir, getSeguidores, getSeguindo, buscar
} = require('./usuarios.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const { listarPorUsuario } = require('../publicacoes/publicacoes.controller');

const router = Router();

/**
 * @swagger
 * /usuarios:
 *   get:
 *     summary: Buscar usuários por nome ou username
 *     tags: [Usuários]
 *     security: []
 *     parameters:
 *       - in: query
 *         name: busca
 *         schema:
 *           type: string
 *         example: joao
 *       - in: query
 *         name: pagina
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: porPagina
 *         schema:
 *           type: integer
 *           default: 20
 *     responses:
 *       200:
 *         description: Lista de usuários
 */
router.get('/', buscar);

/**
 * @swagger
 * /usuarios/me:
 *   get:
 *     summary: Ver perfil próprio
 *     tags: [Usuários]
 *     responses:
 *       200:
 *         description: Dados do usuário autenticado
 *       401:
 *         description: Token inválido
 */
router.get('/me', authMiddleware, getMe);

/**
 * @swagger
 * /usuarios/me:
 *   patch:
 *     summary: Editar perfil próprio
 *     tags: [Usuários]
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nome:
 *                 type: string
 *               bio:
 *                 type: string
 *               localizacao:
 *                 type: string
 *               username:
 *                 type: string
 *               fotoPerfil:
 *                 type: string
 *               banner:
 *                 type: string
 *     responses:
 *       200:
 *         description: Perfil atualizado
 *       400:
 *         description: Validação falhou
 *       409:
 *         description: Username já em uso
 */
router.patch('/me', authMiddleware, updateMe);

/**
 * @swagger
 * /usuarios/username/{username}:
 *   get:
 *     summary: Verificar disponibilidade de username
 *     tags: [Usuários]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: username
 *         required: true
 *         schema:
 *           type: string
 *         example: joaovitor
 *     responses:
 *       200:
 *         description: '{ "data": { "disponivel": true } }'
 */
router.get('/username/:username', checkUsername);

/**
 * @swagger
 * /usuarios/{id}:
 *   get:
 *     summary: Ver perfil de um usuário
 *     tags: [Usuários]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Dados do usuário (souSeguidor e meSegue retornam se autenticado)
 *       404:
 *         description: Usuário não encontrado
 */
router.get('/:id', getPerfil);

/**
 * @swagger
 * /usuarios/{id}/seguidores:
 *   get:
 *     summary: Listar seguidores de um usuário
 *     tags: [Usuários]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: pagina
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: porPagina
 *         schema:
 *           type: integer
 *           default: 20
 *     responses:
 *       200:
 *         description: Lista paginada de seguidores
 */
router.get('/:id/seguidores', getSeguidores);

/**
 * @swagger
 * /usuarios/{id}/seguindo:
 *   get:
 *     summary: Listar quem um usuário segue
 *     tags: [Usuários]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Lista paginada de seguindo
 */
router.get('/:id/seguindo', getSeguindo);

/**
 * @swagger
 * /usuarios/{id}/publicacoes:
 *   get:
 *     summary: Listar publicações de um usuário
 *     tags: [Usuários]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: pagina
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: porPagina
 *         schema:
 *           type: integer
 *           default: 12
 *     responses:
 *       200:
 *         description: Lista paginada de publicações
 */
router.get('/:id/publicacoes', listarPorUsuario);

/**
 * @swagger
 * /usuarios/{id}/seguir:
 *   post:
 *     summary: Seguir usuário (gera notificação)
 *     tags: [Usuários]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       201:
 *         description: Usuário seguido
 *       404:
 *         description: Usuário não encontrado
 *   delete:
 *     summary: Deixar de seguir usuário
 *     tags: [Usuários]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       204:
 *         description: Deixou de seguir
 */
router.post('/:id/seguir', authMiddleware, seguir);
router.delete('/:id/seguir', authMiddleware, deixarDeSeguir);

module.exports = router;