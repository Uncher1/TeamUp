// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const express = require('express');
const pool = require('../config/db');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

router.get('/', authRequired, async (req, res) => {
  const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 50));
  const [rows] = await pool.query(
    `SELECT id, type, title, body, link_type, link_id, is_read, created_at
       FROM notifications WHERE user_id = ?
      ORDER BY created_at DESC LIMIT ?`,
    [req.user.id, limit]
  );
  res.json(rows.map(r => ({ ...r, is_read: !!r.is_read })));
});

router.get('/unread-count', authRequired, async (req, res) => {
  const [rows] = await pool.query(
    'SELECT COUNT(*) AS count FROM notifications WHERE user_id = ? AND is_read = FALSE',
    [req.user.id]
  );
  res.json({ count: rows[0].count });
});

router.post('/:id/read', authRequired, async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: 'invalid id' });
  await pool.query('UPDATE notifications SET is_read = TRUE WHERE id = ? AND user_id = ?', [id, req.user.id]);
  res.json({ ok: true });
});

router.post('/read-all', authRequired, async (req, res) => {
  await pool.query('UPDATE notifications SET is_read = TRUE WHERE user_id = ?', [req.user.id]);
  res.json({ ok: true });
});

module.exports = router;
