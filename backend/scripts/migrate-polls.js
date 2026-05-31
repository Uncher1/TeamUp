// Creates the polls + poll_votes tables (team-conversation polls).
// Idempotent (CREATE TABLE IF NOT EXISTS).
require('dotenv').config();
const pool = require('../src/config/db');

const SQL = [
  `CREATE TABLE IF NOT EXISTS polls (
     id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
     conversation_id INT UNSIGNED NOT NULL,
     message_id      INT UNSIGNED NULL,
     question        VARCHAR(300) NOT NULL,
     options         JSON NOT NULL,
     created_by      INT UNSIGNED NOT NULL,
     created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
     FOREIGN KEY (message_id)      REFERENCES messages(id)      ON DELETE CASCADE,
     FOREIGN KEY (created_by)      REFERENCES users(id)         ON DELETE CASCADE
   ) ENGINE=InnoDB`,
  `CREATE TABLE IF NOT EXISTS poll_votes (
     poll_id      INT UNSIGNED NOT NULL,
     user_id      INT UNSIGNED NOT NULL,
     option_index TINYINT UNSIGNED NOT NULL,
     PRIMARY KEY (poll_id, user_id),
     FOREIGN KEY (poll_id) REFERENCES polls(id) ON DELETE CASCADE,
     FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
   ) ENGINE=InnoDB`,
];

(async () => {
  for (const s of SQL) { await pool.query(s); }
  console.log('ok: polls + poll_votes ready');
  await pool.end();
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
