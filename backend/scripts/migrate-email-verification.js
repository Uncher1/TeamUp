// One-off idempotent migration: add e-mail verification columns to users.
// Safe to re-run (ADD COLUMN IF NOT EXISTS, MariaDB 10.4+).
require('dotenv').config();
const pool = require('../src/config/db');

const cols = [
  ['email_verified', 'TINYINT(1) NOT NULL DEFAULT 0'],
  ['verification_code', 'VARCHAR(9) NULL'],
  ['verification_expires', 'DATETIME NULL'],
];

(async () => {
  for (const [name, type] of cols) {
    await pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS ${name} ${type}`);
    console.log('ok:', name);
  }
  // Existing accounts (seed data) are considered already verified so the demo
  // login flow is not interrupted. New sign-ups start unverified.
  await pool.query('UPDATE users SET email_verified = 1 WHERE verification_code IS NULL');
  console.log('marked existing users verified');
  await pool.end();
  console.log('migration done');
})().catch((e) => {
  console.error('migration failed:', e.message);
  process.exit(1);
});
