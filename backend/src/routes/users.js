const express = require('express');
const pool = require('../config/db');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

async function loadProfile(userId) {
  const [users] = await pool.query(
    'SELECT id, email, full_name, bio, avatar_url, created_at FROM users WHERE id = ?',
    [userId]
  );
  if (!users.length) return null;
  const [skills] = await pool.query(
    `SELECT s.id, s.name, s.category, us.level
       FROM user_skills us JOIN skills s ON s.id = us.skill_id
      WHERE us.user_id = ?`,
    [userId]
  );
  const [interests] = await pool.query(
    `SELECT i.id, i.name
       FROM user_interests ui JOIN interests i ON i.id = ui.interest_id
      WHERE ui.user_id = ?`,
    [userId]
  );
  return { ...users[0], skills, interests };
}

router.get('/me', authRequired, async (req, res) => {
  const profile = await loadProfile(req.user.id);
  if (!profile) return res.status(404).json({ error: 'user not found' });
  res.json(profile);
});

router.patch('/me', authRequired, async (req, res) => {
  const { full_name, bio, avatar_url } = req.body || {};
  await pool.query(
    `UPDATE users SET
        full_name  = COALESCE(?, full_name),
        bio        = COALESCE(?, bio),
        avatar_url = COALESCE(?, avatar_url)
      WHERE id = ?`,
    [full_name ?? null, bio ?? null, avatar_url ?? null, req.user.id]
  );
  res.json(await loadProfile(req.user.id));
});

router.put('/me/skills', authRequired, async (req, res) => {
  const items = Array.isArray(req.body) ? req.body : [];
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    await conn.query('DELETE FROM user_skills WHERE user_id = ?', [req.user.id]);
    for (const it of items) {
      const skillId = Number(it.skill_id);
      const level = Math.max(1, Math.min(5, Number(it.level) || 3));
      if (!skillId) continue;
      await conn.query(
        'INSERT IGNORE INTO user_skills (user_id, skill_id, level) VALUES (?, ?, ?)',
        [req.user.id, skillId, level]
      );
    }
    await conn.commit();
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
  res.json(await loadProfile(req.user.id));
});

router.put('/me/interests', authRequired, async (req, res) => {
  const ids = Array.isArray(req.body) ? req.body.map(Number).filter(Boolean) : [];
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    await conn.query('DELETE FROM user_interests WHERE user_id = ?', [req.user.id]);
    for (const id of ids) {
      await conn.query(
        'INSERT IGNORE INTO user_interests (user_id, interest_id) VALUES (?, ?)',
        [req.user.id, id]
      );
    }
    await conn.commit();
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
  res.json(await loadProfile(req.user.id));
});

router.get('/:id', authRequired, async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: 'invalid id' });
  const profile = await loadProfile(id);
  if (!profile) return res.status(404).json({ error: 'user not found' });
  res.json(profile);
});

module.exports = router;
