// Adds messages.edited (bool) so the UI can show a grey "edited" marker on
// messages whose text was changed after sending. Idempotent.
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  try {
    await pool.query('ALTER TABLE messages ADD COLUMN edited TINYINT(1) NOT NULL DEFAULT 0');
    console.log('ok: messages.edited added');
  } catch (e) {
    if (e.code === 'ER_DUP_FIELDNAME') console.log('skip: messages.edited already exists');
    else throw e;
  }
  await pool.end();
  console.log('done');
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
