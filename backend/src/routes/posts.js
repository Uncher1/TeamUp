// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const express = require('express');
const pool = require('../config/db');
const { authRequired } = require('../middleware/auth');

const router = express.Router();
const POST_TYPES = ['project_launch', 'team_update', 'looking_for', 'milestone', 'general'];

// True if the user is a moderator or admin (may moderate others' content).
async function isPrivileged(userId) {
  const [r] = await pool.query('SELECT role FROM users WHERE id = ?', [userId]);
  return ['moderator', 'admin'].includes(r[0]?.role);
}

const FEED_SELECT = `
  SELECT p.id, p.type, p.content, p.comment_count, p.created_at,
         p.author_id, u.full_name AS author_name, u.avatar_url AS author_avatar, u.role AS author_role,
         p.project_id, pr.title AS project_title,
         (SELECT COUNT(*) FROM post_likes WHERE post_id = p.id) AS like_count,
         EXISTS(SELECT 1 FROM post_likes WHERE post_id = p.id AND user_id = ?) AS liked_by_me
    FROM posts p
    JOIN users u ON u.id = p.author_id
    LEFT JOIN projects pr ON pr.id = p.project_id`;

router.get('/', authRequired, async (req, res) => {
  const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 50));
  const before = Number(req.query.before) || null;
  const where = before ? 'WHERE p.id < ?' : '';
  const params = before ? [req.user.id, before, limit] : [req.user.id, limit];
  const [rows] = await pool.query(
    `${FEED_SELECT} ${where} ORDER BY p.created_at DESC, p.id DESC LIMIT ?`,
    params
  );
  res.json(rows.map(r => ({ ...r, liked_by_me: !!r.liked_by_me })));
});

router.post('/', authRequired, async (req, res) => {
  const type = POST_TYPES.includes(req.body?.type) ? req.body.type : 'general';
  const content = (req.body?.content ?? '').trim();
  const projectId = req.body?.project_id ? Number(req.body.project_id) : null;
  if (!content) return res.status(400).json({ error: 'content is required' });
  if (content.length > 4000) return res.status(400).json({ error: 'content too long' });

  const [r] = await pool.query(
    'INSERT INTO posts (author_id, type, content, project_id) VALUES (?, ?, ?, ?)',
    [req.user.id, type, content, projectId]
  );
  const [rows] = await pool.query(
    `${FEED_SELECT} WHERE p.id = ?`,
    [req.user.id, r.insertId]
  );
  res.status(201).json({ ...rows[0], liked_by_me: !!rows[0].liked_by_me });
});

router.post('/:id/like', authRequired, async (req, res) => {
  const postId = Number(req.params.id);
  if (!postId) return res.status(400).json({ error: 'invalid id' });
  const [posts] = await pool.query('SELECT id FROM posts WHERE id = ?', [postId]);
  if (!posts.length) return res.status(404).json({ error: 'post not found' });

  const [existing] = await pool.query(
    'SELECT 1 AS x FROM post_likes WHERE post_id = ? AND user_id = ?',
    [postId, req.user.id]
  );
  let liked;
  if (existing.length) {
    await pool.query('DELETE FROM post_likes WHERE post_id = ? AND user_id = ?', [postId, req.user.id]);
    liked = false;
  } else {
    await pool.query('INSERT INTO post_likes (post_id, user_id) VALUES (?, ?)', [postId, req.user.id]);
    liked = true;
  }
  const [cnt] = await pool.query('SELECT COUNT(*) AS like_count FROM post_likes WHERE post_id = ?', [postId]);
  res.json({ liked, like_count: cnt[0].like_count });
});

router.get('/:id/comments', authRequired, async (req, res) => {
  const postId = Number(req.params.id);
  if (!postId) return res.status(400).json({ error: 'invalid id' });
  const [rows] = await pool.query(
    `SELECT c.id, c.content, c.created_at,
            u.id AS author_id, u.full_name AS author_name, u.avatar_url AS author_avatar,
            u.role AS author_role
       FROM post_comments c JOIN users u ON u.id = c.author_id
      WHERE c.post_id = ?
      ORDER BY c.created_at ASC`,
    [postId]
  );
  res.json(rows);
});

router.post('/:id/comments', authRequired, async (req, res) => {
  const postId = Number(req.params.id);
  if (!postId) return res.status(400).json({ error: 'invalid id' });
  const content = (req.body?.content ?? '').trim();
  if (!content) return res.status(400).json({ error: 'content is required' });
  if (content.length > 2000) return res.status(400).json({ error: 'content too long' });

  const [posts] = await pool.query('SELECT id FROM posts WHERE id = ?', [postId]);
  if (!posts.length) return res.status(404).json({ error: 'post not found' });

  const conn = await pool.getConnection();
  let insertId;
  try {
    await conn.beginTransaction();
    const [r] = await conn.query(
      'INSERT INTO post_comments (post_id, author_id, content) VALUES (?, ?, ?)',
      [postId, req.user.id, content]
    );
    insertId = r.insertId;
    await conn.query('UPDATE posts SET comment_count = comment_count + 1 WHERE id = ?', [postId]);
    await conn.commit();
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
  const [rows] = await pool.query(
    `SELECT c.id, c.content, c.created_at,
            u.id AS author_id, u.full_name AS author_name, u.avatar_url AS author_avatar,
            u.role AS author_role
       FROM post_comments c JOIN users u ON u.id = c.author_id
      WHERE c.id = ?`,
    [insertId]
  );
  res.status(201).json(rows[0]);
});

router.patch('/:id/comments/:cid', authRequired, async (req, res) => {
  const cid = Number(req.params.cid);
  if (!cid) return res.status(400).json({ error: 'invalid id' });
  const content = (req.body?.content ?? '').trim();
  if (!content) return res.status(400).json({ error: 'content is required' });
  if (content.length > 2000) return res.status(400).json({ error: 'content too long' });

  const [rows] = await pool.query('SELECT author_id FROM post_comments WHERE id = ?', [cid]);
  if (!rows.length) return res.status(404).json({ error: 'comment not found' });
  if (rows[0].author_id !== req.user.id) return res.status(403).json({ error: 'not your comment' });

  await pool.query('UPDATE post_comments SET content = ? WHERE id = ?', [content, cid]);
  const [updated] = await pool.query(
    `SELECT c.id, c.content, c.created_at,
            u.id AS author_id, u.full_name AS author_name, u.avatar_url AS author_avatar,
            u.role AS author_role
       FROM post_comments c JOIN users u ON u.id = c.author_id
      WHERE c.id = ?`,
    [cid]
  );
  res.json(updated[0]);
});

router.delete('/:id/comments/:cid', authRequired, async (req, res) => {
  const postId = Number(req.params.id);
  const cid = Number(req.params.cid);
  if (!postId || !cid) return res.status(400).json({ error: 'invalid id' });

  const [rows] = await pool.query('SELECT author_id FROM post_comments WHERE id = ? AND post_id = ?', [cid, postId]);
  if (!rows.length) return res.status(404).json({ error: 'comment not found' });
  if (rows[0].author_id !== req.user.id && !(await isPrivileged(req.user.id))) {
    return res.status(403).json({ error: 'not your comment' });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    await conn.query('DELETE FROM post_comments WHERE id = ?', [cid]);
    await conn.query('UPDATE posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = ?', [postId]);
    await conn.commit();
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
  res.json({ deleted: true });
});

router.delete('/:id', authRequired, async (req, res) => {
  const postId = Number(req.params.id);
  if (!postId) return res.status(400).json({ error: 'invalid id' });
  const [posts] = await pool.query('SELECT author_id FROM posts WHERE id = ?', [postId]);
  if (!posts.length) return res.status(404).json({ error: 'post not found' });
  if (posts[0].author_id !== req.user.id && !(await isPrivileged(req.user.id))) {
    return res.status(403).json({ error: 'not your post' });
  }
  await pool.query('DELETE FROM posts WHERE id = ?', [postId]);
  res.json({ deleted: true });
});

module.exports = router;
