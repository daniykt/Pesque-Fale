const { Router } = require('express');
const {
  getPerfil, getMe, updateMe, checkUsername,
  seguir, deixarDeSeguir, getSeguidores, getSeguindo, buscar
} = require('./usuarios.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const authOpcional = require('../../middlewares/auth-opcional.middleware');
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
 *         description: >-
 *           Dados do usuário autenticado. Diferente do perfil público
 *           (GET /usuarios/{id}), inclui o email do próprio usuário.
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
 *               onboardingConcluido:
 *                 type: boolean
 *                 description: Marca o onboarding como concluído. Somente `true` é aceito; qualquer outro valor é ignorado.
 *                 example: true
 *     responses:
 *       200:
 *         description: Perfil atualizado
 *       400:
 *         description: >-
 *           VALIDATION_ERROR: nome curto, username fora do formato (3-20
 *           caracteres: letras, números, _ ou .) ou nenhum campo para atualizar.
 *       409:
 *         description: >-
 *           USERNAME_JA_CADASTRADO: o username pedido já pertence a outro
 *           usuário.
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
 *         description: >-
 *           Perfil público do usuário. Não inclui o email: ele só é retornado
 *           em GET /usuarios/me. souSeguidor e meSegue retornam se autenticado.
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
 *         description: >-
 *           Lista paginada de seguidores. Cada item traz souSeguidor = true/false
 *           indicando se o viewer autenticado segue aquele usuário; null quando
 *           não autenticado.
 *       404:
 *         description: Usuário não encontrado
 */
router.get('/:id/seguidores', authOpcional, getSeguidores);

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
 *         description: >-
 *           Lista paginada de usuários que o alvo segue. Cada item traz
 *           souSeguidor = true/false indicando se o viewer autenticado segue
 *           aquele usuário; null quando não autenticado.
 *       404:
 *         description: Usuário não encontrado
 */
router.get('/:id/seguindo', authOpcional, getSeguindo);

/**
 * @swagger
 * /usuarios/{id}/publicacoes:
 *   get:
 *     summary: Listar publicações de um usuário
 *     description: >-
 *       Rota pública com autenticação opcional. Cada item vem no mesmo formato
 *       do feed (GET /publicacoes), com os dados do autor. Com token, jaCurtiu
 *       diz se o usuário logado curtiu; sem token (ou com token inválido),
 *       jaCurtiu vem false e não há 401. O email do autor nunca é devolvido.
 *     tags: [Usuários]
 *     security:
 *       - {}
 *       - bearerAuth: []
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
 *           maximum: 48
 *     responses:
 *       200:
 *         description: Lista paginada de publicações, no mesmo formato do feed.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                       autorId:
 *                         type: string
 *                       autorNome:
 *                         type: string
 *                         example: Ana Pescadora
 *                       autorUsername:
 *                         type: string
 *                         nullable: true
 *                         example: ana_pesca
 *                       autorFoto:
 *                         type: string
 *                         nullable: true
 *                         example: https://res.cloudinary.com/...
 *                       pontoId:
 *                         type: string
 *                         nullable: true
 *                       descricao:
 *                         type: string
 *                         nullable: true
 *                       imagemUrl:
 *                         type: string
 *                         nullable: true
 *                       localTexto:
 *                         type: string
 *                         nullable: true
 *                       avaliacaoNota:
 *                         type: number
 *                         nullable: true
 *                       tags:
 *                         type: array
 *                         items:
 *                           type: string
 *                       curtidasCount:
 *                         type: integer
 *                         example: 3
 *                       comentariosCount:
 *                         type: integer
 *                         example: 1
 *                       jaCurtiu:
 *                         type: boolean
 *                         description: false quando não autenticado.
 *                         example: true
 *                       criadoEm:
 *                         type: string
 *                         format: date-time
 *                       atualizadoEm:
 *                         type: string
 *                         format: date-time
 *                 meta:
 *                   type: object
 *                   properties:
 *                     total:
 *                       type: integer
 *                     pagina:
 *                       type: integer
 *                     porPagina:
 *                       type: integer
 *       404:
 *         description: Usuário não encontrado (USUARIO_NAO_ENCONTRADO)
 */
router.get('/:id/publicacoes', authOpcional, listarPorUsuario);

/**
 * @swagger
 * /usuarios/{id}/seguir:
 *   post:
 *     summary: Seguir usuário (gera notificação)
 *     description: >-
 *       Idempotente: seguir quem já sigo responde 201 com o mesmo body e não
 *       gera notificação nova. Só um follow novo notifica o alvo (tipo
 *       seguindo). A notificação leva deVolta = true quando o alvo já seguia
 *       o autor (seguir de volta).
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
 *       404:
 *         description: Id de usuário inválido
 */
router.post('/:id/seguir', authMiddleware, seguir);
router.delete('/:id/seguir', authMiddleware, deixarDeSeguir);

module.exports = router;