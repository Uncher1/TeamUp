const { verify } = require('../utils/jwt');

function authRequired(req, res, next) {
  const header = req.header('Authorization') || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'missing bearer token' });
  }
  try {
    const payload = verify(token);
    req.user = { id: payload.sub, email: payload.email };
    next();
  } catch {
    return res.status(401).json({ error: 'invalid or expired token' });
  }
}

module.exports = { authRequired };
