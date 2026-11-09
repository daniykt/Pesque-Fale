const jwt = require('jsonwebtoken');

function gerarToken(usuarioId = 'user-1') {
  return jwt.sign({ id: usuarioId }, process.env.JWT_SECRET, { expiresIn: '1h' });
}

module.exports = { gerarToken };
