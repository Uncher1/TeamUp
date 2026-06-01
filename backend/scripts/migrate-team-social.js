// Adds projects.allow_member_invite (team setting) + the team_invites table.
// Idempotent (tolerates the duplicate column; CREATE TABLE IF NOT EXISTS).
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  try {
    await pool.query(
      'ALTER TABLE projects ADD COLUMN allow_member_invite TINYINT(1) NOT NULL DEFAULT 0');
    console.log('ok: projects.allow_member_invite added');
  } catch (e) {
    if (e.code === 'ER_DUP_FIELDNAME') console.log('ok: allow_member_invite already present');
    else throw e;
  }
  await pool.query(`CREATE TABLE IF NOT EXISTS team_invites (
     id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
     project_id  INT UNSIGNED NOT NULL,
     invitee_id  INT UNSIGNED NOT NULL,
     inviter_id  INT UNSIGNED NOT NULL,
     status      VARCHAR(10) NOT NULL DEFAULT 'pending',
     created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     UNIQUE KEY uniq_invite (project_id, invitee_id),
     FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
     FOREIGN KEY (invitee_id) REFERENCES users(id)    ON DELETE CASCADE,
     FOREIGN KEY (inviter_id) REFERENCES users(id)    ON DELETE CASCADE
   ) ENGINE=InnoDB`);
  console.log('ok: team_invites ready');
  await pool.end();
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
