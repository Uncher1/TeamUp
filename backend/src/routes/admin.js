// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const express = require('express');
const pool = require('../config/db');
const { authRequired, requireRole } = require('../middleware/auth');
const { deleteUserAndCleanup } = require('../services/accountDeletion');

const router = express.Router();
const ROLES = ['user', 'moderator', 'admin'];

// List users (optionally filtered by name/email) - admin only.
router.get('/users', authRequired, requireRole('admin'), async (req, res) => {
  const q = `%${String(req.query.q ?? '').trim()}%`;
  const [rows] = await pool.query(
    `SELECT id, full_name, email, role, avatar_url, created_at
       FROM users
      WHERE full_name LIKE ? OR email LIKE ?
      ORDER BY (role = 'admin') DESC, (role = 'moderator') DESC, full_name
      LIMIT 200`,
    [q, q]
  );
  res.json(rows);
});

// Promote / demote a user - admin only.
router.patch('/users/:id/role', authRequired, requireRole('admin'), async (req, res) => {
  const id = Number(req.params.id);
  const role = String(req.body?.role ?? '');
  if (!id || !ROLES.includes(role)) {
    return res.status(400).json({ error: 'valid id and role required' });
  }
  // Don't let an admin remove their own admin rights (avoid self-lockout).
  if (id === req.user.id && role !== 'admin') {
    return res.status(400).json({ error: 'you cannot change your own admin role' });
  }
  const [r] = await pool.query('UPDATE users SET role = ? WHERE id = ?', [role, id]);
  if (!r.affectedRows) return res.status(404).json({ error: 'user not found' });
  res.json({ id, role });
});

// Permanently delete a user account - admin only. Cascades to all their data.
router.delete('/users/:id', authRequired, requireRole('admin'), async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: 'valid id required' });
  // Admins delete their OWN account from Settings (with the proper flow), not here.
  if (id === req.user.id) {
    return res.status(400).json({ error: 'use Settings to delete your own account' });
  }
  const affected = await deleteUserAndCleanup(id);
  if (!affected) return res.status(404).json({ error: 'user not found' });
  res.json({ deleted: true, id });
});

module.exports = router;
