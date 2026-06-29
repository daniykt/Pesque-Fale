const express = require('express');
const authRoutes = require('./modules/auth/auth.routes');
require('dotenv').config();

const app = express();

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Pesque & Fale API rodando!' });
});

app.use('/v1/auth', authRoutes);

module.exports = app;