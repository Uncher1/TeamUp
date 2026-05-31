// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

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

// Guards a route so only the given roles may pass. Loads the CURRENT role
// from the DB (roles can change after a token was issued). Use after
// authRequired, e.g. router.delete('/x', authRequired, requireRole('admin'), ...).
const pool = require('../config/db');
function requireRole(...allowed) {
  return async (req, res, next) => {
    try {
      const [rows] = await pool.query('SELECT role FROM users WHERE id = ?', [req.user.id]);
      const role = rows[0]?.role ?? 'user';
      if (!allowed.includes(role)) {
        return res.status(403).json({ error: 'insufficient permissions' });
      }
      req.user.role = role;
      next();
    } catch (e) {
      next(e);
    }
  };
}

module.exports = { authRequired, requireRole };
