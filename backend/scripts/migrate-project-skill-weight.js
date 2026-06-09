// Adds projects.skill_weight: the team chief's chosen importance of skills vs
// interests in matching (0..1, where 0.70 = the old fixed 70% skills / 30%
// interests). Idempotent.
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  try {
    await pool.query(
      'ALTER TABLE projects ADD COLUMN skill_weight DECIMAL(3,2) NOT NULL DEFAULT 0.70'
    );
    console.log('ok: projects.skill_weight added');
  } catch (e) {
    if (e.code === 'ER_DUP_FIELDNAME') console.log('skip: projects.skill_weight already exists');
    else throw e;
  }
  await pool.end();
  console.log('done');
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
