// One-off schema loader for a fresh database (e.g. a hosting provider where the
// DB already exists and the app user cannot CREATE DATABASE).
// Reads db/schema.sql, strips the `CREATE DATABASE` / `USE` header lines, and
// runs the remaining CREATE TABLE statements against the DB in the env config.
//   DB_HOST=... DB_USER=... DB_PASSWORD=... DB_NAME=... node scripts/load-schema.js
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

(async () => {
  const sql = fs.readFileSync(path.join(__dirname, '..', 'db', 'schema.sql'), 'utf8')
    // drop the `CREATE DATABASE ...;` and `USE ...;` statements — the hosted DB
    // already exists and is selected via the connection config.
    .replace(/CREATE DATABASE[\s\S]*?;/i, '')
    .replace(/USE\s+\w+\s*;/i, '');

  const ssl = process.env.DB_SSL === 'true'
    ? (process.env.DB_SSL_CA ? { ca: process.env.DB_SSL_CA } : { rejectUnauthorized: false })
    : undefined;

  const conn = await mysql.createConnection({
    host:     process.env.DB_HOST     || 'localhost',
    port:     Number(process.env.DB_PORT) || 3306,
    user:     process.env.DB_USER     || 'teamup',
    password: process.env.DB_PASSWORD ?? 'teamup',
    database: process.env.DB_NAME     || 'teamup',
    ...(ssl ? { ssl } : {}),
    multipleStatements: true,
  });

  console.log(`Connected to ${process.env.DB_NAME} @ ${process.env.DB_HOST}`);
  await conn.query(sql);
  const [tables] = await conn.query('SHOW TABLES');
  console.log(`Schema loaded. ${tables.length} tables:`);
  for (const row of tables) console.log('  -', Object.values(row)[0]);
  await conn.end();
})().catch((e) => {
  console.error('Schema load failed:', e.message);
  process.exit(1);
});
