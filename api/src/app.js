const express = require('express');
const authRoutes = require('./modules/auth/auth.routes');
const usuariosRoutes = require('./modules/usuarios/usuarios.routes');
const uploadRoutes = require('./modules/upload/upload.routes');
const pontosRoutes = require('./modules/pontos/pontos.routes');
const avaliacoesRoutes = require('./modules/avaliacoes/avaliacoes.routes');
const publicacoesRoutes = require('./modules/publicacoes/publicacoes.routes');
require('dotenv').config();

const app = express();

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Pesque & Fale API rodando!' });
});

app.use('/v1/auth', authRoutes);
app.use('/v1/usuarios', usuariosRoutes);
app.use('/v1/usuarios', uploadRoutes);
app.use('/v1/usuarios/:id/publicacoes', publicacoesRoutes);
app.use('/v1/pontos', pontosRoutes);
app.use('/v1/pontos/:pontoId/avaliacoes', avaliacoesRoutes);
app.use('/v1/publicacoes', publicacoesRoutes);

module.exports = app;