// Adds an optional image (base64 data URL) to feed posts.
// Idempotent (ignores "column already exists").
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  try {
    await pool.query('ALTER TABLE posts ADD COLUMN image MEDIUMTEXT NULL');
    console.log('ok: posts.image added');
  } catch (e) {
    if (e.code === 'ER_DUP_FIELDNAME') console.log('skip: posts.image already exists');
    else throw e;
  }
  await pool.end();
  console.log('done');
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
