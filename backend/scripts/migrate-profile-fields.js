// One-off idempotent migration: add profile detail + social columns to users.
// Safe to re-run (ADD COLUMN IF NOT EXISTS, MariaDB 10.4+).
require('dotenv').config();
const pool = require('../src/config/db');

const cols = [
  ['phone', 'VARCHAR(40)'],
  ['school', 'VARCHAR(120)'],
  ['department', 'VARCHAR(120)'],
  ['study_year', 'VARCHAR(40)'],
  ['location', 'VARCHAR(120)'],
  ['github', 'VARCHAR(120)'],
  ['linkedin', 'VARCHAR(120)'],
  ['twitter', 'VARCHAR(120)'],
  ['website', 'VARCHAR(200)'],
];

(async () => {
  for (const [name, type] of cols) {
    await pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS ${name} ${type} NULL`);
    console.log('ok:', name);
  }
  await pool.end();
  console.log('migration done');
})().catch((e) => {
  console.error('migration failed:', e.message);
  process.exit(1);
});
