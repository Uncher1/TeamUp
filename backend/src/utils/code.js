// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const crypto = require('crypto');

// Generates an XXXX-XXXX confirmation code (uppercase letters + digits).
function generateCode() {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let raw = '';
  for (let i = 0; i < 8; i++) raw += alphabet[crypto.randomInt(alphabet.length)];
  return `${raw.slice(0, 4)}-${raw.slice(4)}`;
}

module.exports = { generateCode };
