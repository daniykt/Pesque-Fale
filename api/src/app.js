const express = require('express');
const cors = require('cors');
const authRoutes = require('./modules/auth/auth.routes');
const usuariosRoutes = require('./modules/usuarios/usuarios.routes');
const uploadRoutes = require('./modules/upload/upload.routes');
const pontosRoutes = require('./modules/pontos/pontos.routes');
const avaliacoesRoutes = require('./modules/avaliacoes/avaliacoes.routes');
const publicacoesRoutes = require('./modules/publicacoes/publicacoes.routes');
const eventosRoutes = require('./modules/eventos/eventos.routes');
const chatRoutes = require('./modules/chat/chat.routes');
const notificacoesRoutes = require('./modules/notificacoes/notificacoes.routes');
require('dotenv').config();

const app = express();

app.use(cors());
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
app.use('/v1/eventos', eventosRoutes);
app.use('/v1/chats', chatRoutes);
app.use('/v1/notificacoes', notificacoesRoutes);

module.exports = app;