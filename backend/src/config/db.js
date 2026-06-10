// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const mysql = require('mysql2/promise');

// Managed MySQL providers (e.g. Aiven) require TLS. Enable it with DB_SSL=true.
// Optionally pin the provider CA with DB_SSL_CA (PEM contents); otherwise we
// connect over TLS without CA pinning.
let ssl;
if (process.env.DB_SSL === 'true') {
  ssl = process.env.DB_SSL_CA
    ? { ca: process.env.DB_SSL_CA }
    : { rejectUnauthorized: false };
}

const pool = mysql.createPool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     Number(process.env.DB_PORT) || 3306,
  user:     process.env.DB_USER     || 'teamup',
  password: process.env.DB_PASSWORD ?? 'teamup',
  database: process.env.DB_NAME     || 'teamup',
  ...(ssl ? { ssl } : {}),
  waitForConnections: true,
  connectionLimit: 10,
  timezone: 'Z'
});

module.exports = pool;
