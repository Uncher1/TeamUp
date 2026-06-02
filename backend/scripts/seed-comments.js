// Idempotent: seed a few demo comments on the demo posts and reconcile every
// post's comment_count to the real number of comments. Safe to re-run.
require('dotenv').config();
const pool = require('../src/config/db');

// (postId, authorId, content) - authors are the seed users (1..6).
const COMMENTS = [
  [1, 2, 'Super idée ! Je suis dispo pour aider côté backend.'],
  [1, 3, 'Le concept de révision entre pairs est top, je veux participer.'],
  [1, 1, "Merci ! On démarre la semaine prochaine, je vous tiens au courant."],
  [2, 4, 'OpenLab a l\'air prometteur, tu vises quelle stack ?'],
  [2, 1, 'Intéressée par le marketplace, je peux faire le design.'],
  [3, 5, 'Bravo pour les 100 beta-testeurs 🎉'],
  [4, 6, 'CampusBot pourrait répondre aux questions de scolarité, génial.'],
];

(async () => {
  // Only seed when there are no comments yet (idempotent).
  const [[{ n }]] = await pool.query('SELECT COUNT(*) AS n FROM post_comments');
  if (n === 0) {
    for (const [postId, authorId, content] of COMMENTS) {
      const [[p]] = await pool.query('SELECT id FROM posts WHERE id = ?', [postId]);
      const [[u]] = await pool.query('SELECT id FROM users WHERE id = ?', [authorId]);
      if (p && u) {
        await pool.query(
          'INSERT INTO post_comments (post_id, author_id, content) VALUES (?, ?, ?)',
          [postId, authorId, content]
        );
      }
    }
    console.log('inserted demo comments');
  } else {
    console.log(`post_comments already has ${n} rows - skipping insert`);
  }
  // Reconcile every post's comment_count with the real count.
  await pool.query(
    `UPDATE posts p
        SET comment_count = (SELECT COUNT(*) FROM post_comments c WHERE c.post_id = p.id)`
  );
  console.log('reconciled comment_count for all posts');
  await pool.end();
})().catch((e) => {
  console.error('seed failed:', e.message);
  process.exit(1);
});
