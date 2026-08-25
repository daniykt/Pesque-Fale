const jwt = require('jsonwebtoken');

module.exports = (req, _res, next) => {
  const header = req.headers.authorization;
  if (header?.startsWith('Bearer ')) {
    try {
      const token = header.slice(7);
      req.usuario = jwt.verify(token, process.env.JWT_SECRET);
    } catch (_) {
      // token inválido — segue sem usuário
    }
  }
  next();
};
