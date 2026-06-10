// Adds users.is_student: whether a user marks themselves as a student, which
// gates the optional Academic profile section (school / field of study / year).
// Existing users who already have academic data are marked as students so their
// section stays visible (no regression). Idempotent / safe to re-run.
//
// MySQL-8-safe: ADD COLUMN IF NOT EXISTS is MariaDB-only, so we attempt the ADD
// and treat a duplicate-column error as "already there".
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  try {
    await pool.query(
      'ALTER TABLE users ADD COLUMN is_student TINYINT(1) NOT NULL DEFAULT 0'
    );
    console.log('ok: users.is_student added');
  } catch (e) {
    if (e.code === 'ER_DUP_FIELDNAME') console.log('skip: users.is_student already exists');
    else throw e;
  }

  // Back-fill: anyone with existing academic data is treated as a student.
  const [r] = await pool.query(
    `UPDATE users SET is_student = 1
       WHERE is_student = 0
         AND ((school     IS NOT NULL AND school     <> '')
           OR (department IS NOT NULL AND department <> '')
           OR (study_year IS NOT NULL AND study_year <> ''))`
  );
  console.log(`ok: marked ${r.affectedRows} existing user(s) with academic data as students`);

  await pool.end();
  console.log('migration done');
})().catch((e) => {
  console.error('migration failed:', e.message);
  process.exit(1);
});
