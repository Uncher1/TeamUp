// One-off idempotent migration: add a moderation role to users.
// role ∈ {'user','moderator','admin'} — default 'user'. Safe to re-run.
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  await pool.query(
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) NOT NULL DEFAULT 'user'"
  );
  console.log('ok: role column');
  await pool.end();
  console.log('migration done');
})().catch((e) => {
  console.error('migration failed:', e.message);
  process.exit(1);
});
