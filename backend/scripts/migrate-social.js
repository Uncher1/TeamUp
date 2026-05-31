// Creates the social tables (friendships, blocks, reports) and extends the
// notifications type enum with friend_request / friend_accept.
// Idempotent: CREATE TABLE IF NOT EXISTS + re-applying the same enum is a no-op.
require('dotenv').config();
const pool = require('../src/config/db');

const SQL = [
  `CREATE TABLE IF NOT EXISTS friendships (
     id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
     requester_id  INT UNSIGNED NOT NULL,
     addressee_id  INT UNSIGNED NOT NULL,
     status        VARCHAR(10) NOT NULL DEFAULT 'pending', -- pending | accepted
     created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     UNIQUE KEY uniq_pair (requester_id, addressee_id),
     FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE CASCADE,
     FOREIGN KEY (addressee_id) REFERENCES users(id) ON DELETE CASCADE
   ) ENGINE=InnoDB`,
  `CREATE TABLE IF NOT EXISTS blocks (
     blocker_id  INT UNSIGNED NOT NULL,
     blocked_id  INT UNSIGNED NOT NULL,
     created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     PRIMARY KEY (blocker_id, blocked_id),
     FOREIGN KEY (blocker_id) REFERENCES users(id) ON DELETE CASCADE,
     FOREIGN KEY (blocked_id) REFERENCES users(id) ON DELETE CASCADE
   ) ENGINE=InnoDB`,
  `CREATE TABLE IF NOT EXISTS reports (
     id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
     reporter_id       INT UNSIGNED NOT NULL,
     reported_user_id  INT UNSIGNED NOT NULL,
     reason            VARCHAR(60) NOT NULL,
     details           TEXT,
     created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     FOREIGN KEY (reporter_id)      REFERENCES users(id) ON DELETE CASCADE,
     FOREIGN KEY (reported_user_id) REFERENCES users(id) ON DELETE CASCADE
   ) ENGINE=InnoDB`,
  `ALTER TABLE notifications MODIFY COLUMN type
     ENUM('team_invite','message','project_update','mention',
          'team_join','project_complete','application',
          'friend_request','friend_accept') NOT NULL`,
];

(async () => {
  for (const s of SQL) { await pool.query(s); }
  console.log('ok: friendships + blocks + reports ready, notifications enum extended');
  await pool.end();
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
