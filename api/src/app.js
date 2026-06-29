const express = require('express');
const authRoutes = require('./modules/auth/auth.routes');
const usuariosRoutes = require('./modules/usuarios/usuarios.routes');
require('dotenv').config();

const app = express();

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Pesque & Fale API rodando!' });
});

app.use('/v1/auth', authRoutes);
app.use('/v1/usuarios', usuariosRoutes);

module.exports = app;