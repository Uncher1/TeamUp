// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const pool = require('../config/db');

/**
 * Deletes a user and cleans up everything they touched.
 *
 * Most content is removed automatically by the schema's `ON DELETE CASCADE`
 * foreign keys: their posts, comments, likes, messages, poll votes, project
 * memberships (and owned projects), friendships, blocks, reports, invites,
 * notifications, skills/interests. Live-computed counters (likes via COUNT
 * subquery) self-correct.
 *
 * The ONE thing cascades can't fix is the DENORMALISED `posts.comment_count`
 * stored column: when this user's comments on OTHER people's posts are
 * cascade-deleted, that column would stay too high. So we recompute it for
 * exactly the affected posts (inside the same transaction).
 *
 * @returns the number of user rows deleted (0 if the user didn't exist).
 */
async function deleteUserAndCleanup(userId) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    // Posts that will need a comment-count refresh after the cascade.
    const [affected] = await conn.query(
      'SELECT DISTINCT post_id FROM post_comments WHERE author_id = ?', [userId]);
    const [r] = await conn.query('DELETE FROM users WHERE id = ?', [userId]);
    if (affected.length) {
      const ids = affected.map((x) => x.post_id);
      await conn.query(
        `UPDATE posts SET comment_count =
           (SELECT COUNT(*) FROM post_comments WHERE post_id = posts.id)
         WHERE id IN (?)`,
        [ids]
      );
    }
    await conn.commit();
    return r.affectedRows;
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
}

module.exports = { deleteUserAndCleanup };
