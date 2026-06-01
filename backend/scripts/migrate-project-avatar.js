// Adds projects.avatar_url (team photo, base64 data URL). Idempotent.
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  try {
    await pool.query('ALTER TABLE projects ADD COLUMN avatar_url MEDIUMTEXT');
    console.log('ok: projects.avatar_url added');
  } catch (e) {
    if (e.code === 'ER_DUP_FIELDNAME') {
      console.log('ok: projects.avatar_url already present');
    } else {
      throw e;
    }
  }
  await pool.end();
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
