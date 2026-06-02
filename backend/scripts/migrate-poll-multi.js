// Adds multi-choice support to polls:
//   - polls.multi (0 = single choice, 1 = multiple choice)
//   - poll_votes PK becomes (poll_id, user_id, option_index) so a user can
//     select several options in a multi-choice poll.
// Idempotent: safe to run repeatedly (ignores "already done" errors).
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  // 1. polls.multi
  try {
    await pool.query('ALTER TABLE polls ADD COLUMN multi TINYINT(1) NOT NULL DEFAULT 0');
    console.log('ok: polls.multi added');
  } catch (e) {
    if (e.code === 'ER_DUP_FIELDNAME') console.log('skip: polls.multi already exists');
    else throw e;
  }

  // 2. poll_votes triple PK (poll_id, user_id, option_index)
  try {
    await pool.query(
      'ALTER TABLE poll_votes DROP PRIMARY KEY, ADD PRIMARY KEY (poll_id, user_id, option_index)');
    console.log('ok: poll_votes PK -> (poll_id, user_id, option_index)');
  } catch (e) {
    // Already the triple PK (re-run) or table shape differs - non-fatal.
    console.log('skip: poll_votes PK change (', e.code || e.message, ')');
  }

  await pool.end();
  console.log('done');
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
