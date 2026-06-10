// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const bcrypt = require('bcryptjs');

const ROUNDS = 10;

const hash   = (password)             => bcrypt.hash(password, ROUNDS);
const verify = (password, storedHash) => bcrypt.compare(password, storedHash);

module.exports = { hash, verify };
