// One-off idempotent migration: add category/team_size/timeline to projects.
// Safe to re-run (uses ADD COLUMN IF NOT EXISTS, supported by MariaDB 10.4+).
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  const stmts = [
    "ALTER TABLE projects ADD COLUMN IF NOT EXISTS category VARCHAR(40) NULL AFTER description",
    "ALTER TABLE projects ADD COLUMN IF NOT EXISTS team_size TINYINT UNSIGNED NULL AFTER category",
    "ALTER TABLE projects ADD COLUMN IF NOT EXISTS timeline VARCHAR(20) NULL AFTER team_size",
  ];
  for (const s of stmts) {
    await pool.query(s);
    console.log('ok:', s);
  }
  await pool.end();
  console.log('migration done');
})().catch((e) => {
  console.error('migration failed:', e.message);
  process.exit(1);
});
