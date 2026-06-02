// Adds messages.attachments (JSON array) so a single chat message can carry up
// to 10 images/files. The legacy single-attachment columns stay for audio,
// polls and older messages. Idempotent.
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  try {
    await pool.query('ALTER TABLE messages ADD COLUMN attachments JSON NULL');
    console.log('ok: messages.attachments added');
  } catch (e) {
    if (e.code === 'ER_DUP_FIELDNAME') console.log('skip: messages.attachments already exists');
    else throw e;
  }
  await pool.end();
  console.log('done');
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
