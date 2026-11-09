const { Router } = require('express');
const { cadastro, login } = require('./auth.controller');

const router = Router();

/**
 * @swagger
 * /auth/cadastro:
 *   post:
 *     summary: Cadastro de novo usuário
 *     tags: [Auth]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [nome, email, senha, confirmarSenha]
 *             properties:
 *               nome:
 *                 type: string
 *                 example: João Vítor
 *               email:
 *                 type: string
 *                 example: joao@email.com
 *               senha:
 *                 type: string
 *                 example: "123456"
 *               confirmarSenha:
 *                 type: string
 *                 example: "123456"
 *     responses:
 *       201:
 *         description: Cadastro realizado com sucesso
 *       400:
 *         description: Validação falhou
 *       409:
 *         description: Email já cadastrado
 */
router.post('/cadastro', cadastro);

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Login de usuário
 *     tags: [Auth]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, senha]
 *             properties:
 *               email:
 *                 type: string
 *                 example: joao@email.com
 *               senha:
 *                 type: string
 *                 example: "123456"
 *     responses:
 *       200:
 *         description: Login realizado com sucesso
 *       401:
 *         description: Credenciais inválidas
 */
router.post('/login', login);

module.exports = router;