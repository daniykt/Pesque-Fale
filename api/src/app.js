const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./config/swagger');
const authRoutes = require('./modules/auth/auth.routes');
const usuariosRoutes = require('./modules/usuarios/usuarios.routes');
const uploadRoutes = require('./modules/upload/upload.routes');
const pontosRoutes = require('./modules/pontos/pontos.routes');
const avaliacoesRoutes = require('./modules/avaliacoes/avaliacoes.routes');
const publicacoesRoutes = require('./modules/publicacoes/publicacoes.routes');
const eventosRoutes = require('./modules/eventos/eventos.routes');
const chatRoutes = require('./modules/chat/chat.routes');
const notificacoesRoutes = require('./modules/notificacoes/notificacoes.routes');
const curtidasRoutes = require('./modules/curtidas/curtidas.routes');
const comentariosRoutes = require('./modules/comentarios/comentarios.routes');
const comentariosStandaloneRoutes = require('./modules/comentarios/comentarios-standalone.routes');
const rejeitarBase64 = require('./middlewares/rejeitar-base64.middleware');
require('dotenv').config();

const app = express();

app.use(cors());
app.use(express.json());

app.use((err, req, res, next) => {
  if (err && err.type === 'entity.too.large') {
    return res.status(413).json({
      error: 'PAYLOAD_MUITO_GRANDE',
      message:
        'Corpo da requisição muito grande. Imagem deve ser enviada em multipart/form-data, não dentro do JSON.',
      details: [{ campo: 'body', mensagem: 'Corpo acima do limite permitido.' }],
    });
  }
  return next(err);
});

app.use(rejeitarBase64);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Pesque & Fale API rodando!' });
});

app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.get('/docs.json', (req, res) => res.json(swaggerSpec));

app.use('/v1/auth', authRoutes);
app.use('/v1/usuarios', usuariosRoutes);
app.use('/v1/usuarios', uploadRoutes);
app.use('/v1/usuarios/:id/publicacoes', publicacoesRoutes);
app.use('/v1/pontos', pontosRoutes);
app.use('/v1/pontos/:pontoId/avaliacoes', avaliacoesRoutes);
app.use('/v1/publicacoes', publicacoesRoutes);
app.use('/v1/publicacoes', uploadRoutes);
app.use('/v1/publicacoes/:publicacaoId/curtir', curtidasRoutes);
app.use('/v1/publicacoes/:publicacaoId/comentarios', comentariosRoutes);
app.use('/v1/comentarios', comentariosStandaloneRoutes);
app.use('/v1/eventos', eventosRoutes);
app.use('/v1/chats', chatRoutes);
app.use('/v1/notificacoes', notificacoesRoutes);

module.exports = app;