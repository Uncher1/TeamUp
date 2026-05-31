// Adds users.presence_status (Discord-style: online | dnd | offline).
// MySQL 8 has no "ADD COLUMN IF NOT EXISTS", so we tolerate the duplicate-column
// error to stay idempotent.
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  try {
    await pool.query(
      "ALTER TABLE users ADD COLUMN presence_status VARCHAR(10) NOT NULL DEFAULT 'online'"
    );
    console.log('ok: users.presence_status added');
  } catch (e) {
    if (e.code === 'ER_DUP_FIELDNAME') {
      console.log('ok: users.presence_status already present');
    } else {
      throw e;
    }
  }
  await pool.end();
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
