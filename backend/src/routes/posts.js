const express = require('express');
const pool = require('../config/db');
const { authRequired } = require('../middleware/auth');

const router = express.Router();
const POST_TYPES = ['project_launch', 'team_update', 'looking_for', 'milestone', 'general'];

const FEED_SELECT = `
  SELECT p.id, p.type, p.content, p.comment_count, p.created_at,
         p.author_id, u.full_name AS author_name, u.avatar_url AS author_avatar,
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

router.delete('/:id', authRequired, async (req, res) => {
  const postId = Number(req.params.id);
  if (!postId) return res.status(400).json({ error: 'invalid id' });
  const [posts] = await pool.query('SELECT author_id FROM posts WHERE id = ?', [postId]);
  if (!posts.length) return res.status(404).json({ error: 'post not found' });
  if (posts[0].author_id !== req.user.id) return res.status(403).json({ error: 'not your post' });
  await pool.query('DELETE FROM posts WHERE id = ?', [postId]);
  res.json({ deleted: true });
});

module.exports = router;
