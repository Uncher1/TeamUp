// One-shot maintenance: recompute every post's stored comment_count from the
// actual rows in post_comments. Fixes counts left stale by comments that were
// removed via cascade before the deletion-cleanup fix shipped.
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  const [r] = await pool.query(
    `UPDATE posts SET comment_count =
       (SELECT COUNT(*) FROM post_comments WHERE post_id = posts.id)`
  );
  console.log(`ok: recomputed comment_count (${r.affectedRows} posts touched)`);
  await pool.end();
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
