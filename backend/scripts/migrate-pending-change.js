// One-off idempotent migration: columns to hold a PENDING e-mail/password
// change awaiting confirmation by a code sent to the user's e-mail.
// Safe to re-run (ADD COLUMN IF NOT EXISTS, MariaDB 10.4+).
require('dotenv').config();
const pool = require('../src/config/db');

const cols = [
  ['pending_change_type', "VARCHAR(10) NULL"],     // 'email' | 'password'
  ['pending_email', 'VARCHAR(255) NULL'],
  ['pending_password_hash', 'VARCHAR(255) NULL'],
  ['pending_change_code', 'VARCHAR(9) NULL'],
  ['pending_change_expires', 'DATETIME NULL'],
];

(async () => {
  for (const [name, type] of cols) {
    await pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS ${name} ${type}`);
    console.log('ok:', name);
  }
  await pool.end();
  console.log('migration done');
})().catch((e) => {
  console.error('migration failed:', e.message);
  process.exit(1);
});
