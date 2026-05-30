// One-off idempotent migration: create the post_comments table. Safe to re-run.
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS post_comments (
      id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      post_id    INT UNSIGNED NOT NULL,
      author_id  INT UNSIGNED NOT NULL,
      content    VARCHAR(2000) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      KEY idx_post_comments_post (post_id, created_at),
      FOREIGN KEY (post_id)   REFERENCES posts(id) ON DELETE CASCADE,
      FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB
  `);
  console.log('ok: post_comments table');
  await pool.end();
})().catch((e) => {
  console.error('migration failed:', e.message);
  process.exit(1);
});
