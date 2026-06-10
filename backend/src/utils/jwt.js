// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const jwt = require('jsonwebtoken');

const SECRET     = process.env.JWT_SECRET;
const EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

if (!SECRET) {
  console.error('JWT_SECRET is not set. Refusing to start.');
  process.exit(1);
}

const sign   = (payload) => jwt.sign(payload, SECRET, { expiresIn: EXPIRES_IN });
const verify = (token)   => jwt.verify(token, SECRET);

module.exports = { sign, verify };
