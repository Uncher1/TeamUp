// Adds posts.language (BCP-47-ish 'en'/'fr'), used to offer in-app translation
// of a post into the viewer's language. Idempotent (tolerates duplicate column).
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  try {
    await pool.query("ALTER TABLE posts ADD COLUMN language VARCHAR(5) NOT NULL DEFAULT 'en'");
    console.log('ok: posts.language added');
  } catch (e) {
    if (e.code === 'ER_DUP_FIELDNAME') {
      console.log('ok: posts.language already present');
    } else {
      throw e;
    }
  }
  await pool.end();
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
