const http = require('http');
const { Server } = require('socket.io');
const app = require('./app');
const socketEmitter = require('./config/socket-emitter');
const { opcoesSocket } = require('./config/cors-socket');
const initChatGateway = require('./modules/chat/chat.gateway');
require('dotenv').config();

const PORT = process.env.PORT || 3333;

const server = http.createServer(app);

const io = new Server(server, opcoesSocket());

socketEmitter.init(io);
initChatGateway(io);

server.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});