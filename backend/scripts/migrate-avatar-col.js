// One-off idempotent migration: widen users.avatar_url to MEDIUMTEXT so it can
// hold a base64 data URL (profile photo). Safe to re-run.
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  await pool.query('ALTER TABLE users MODIFY avatar_url MEDIUMTEXT NULL');
  console.log('ok: avatar_url -> MEDIUMTEXT');
  await pool.end();
})().catch((e) => {
  console.error('migration failed:', e.message);
  process.exit(1);
});
