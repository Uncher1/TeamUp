// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

// Social graph endpoints: friend requests, blocking and reporting.
// Mounted at /api (AFTER the /api/users router so /users/me etc. resolve first).
const express = require('express');
const pool = require('../config/db');
const { authRequired } = require('../middleware/auth');
const { createNotification } = require('../services/notifications');
const { sendAbuseReport } = require('../services/mailer');
const { applyPresenceVisibility } = require('../services/presence');
const { ensureDirectConversation } = require('../services/chat');

const router = express.Router();

const MINI = 'u.id, u.full_name, u.avatar_url, u.role, u.presence_status';

async function friendshipBetween(a, b) {
  const [rows] = await pool.query(
    `SELECT * FROM friendships
      WHERE (requester_id = ? AND addressee_id = ?)
         OR (requester_id = ? AND addressee_id = ?) LIMIT 1`,
    [a, b, b, a]
  );
  return rows[0] || null;
}

async function isBlockedEitherWay(a, b) {
  const [rows] = await pool.query(
    `SELECT 1 FROM blocks
      WHERE (blocker_id = ? AND blocked_id = ?)
         OR (blocker_id = ? AND blocked_id = ?) LIMIT 1`,
    [a, b, b, a]
  );
  return rows.length > 0;
}

/// Relationship of [otherId] from [meId]'s point of view.
/// Returns { friend_status: none|outgoing|incoming|friends, blocked, blocked_by }.
async function relationship(meId, otherId) {
  const f = await friendshipBetween(meId, otherId);
  let friend_status = 'none';
  if (f) {
    if (f.status === 'accepted') friend_status = 'friends';
    else friend_status = f.requester_id === meId ? 'outgoing' : 'incoming';
  }
  const [[blk]] = await pool.query(
    'SELECT COUNT(*) AS n FROM blocks WHERE blocker_id = ? AND blocked_id = ?',
    [meId, otherId]
  );
  const [[blkBy]] = await pool.query(
    'SELECT COUNT(*) AS n FROM blocks WHERE blocker_id = ? AND blocked_id = ?',
    [otherId, meId]
  );
  return { friend_status, blocked: blk.n > 0, blocked_by: blkBy.n > 0 };
}

async function userName(id) {
  const [rows] = await pool.query('SELECT full_name FROM users WHERE id = ?', [id]);
  return rows.length ? rows[0].full_name : 'Quelqu’un';
}

function parseTarget(req, res) {
  const other = Number(req.params.userId);
  if (!other || other === req.user.id) {
    res.status(400).json({ error: 'invalid target user' });
    return null;
  }
  return other;
}

// ── Friends ──────────────────────────────────────────────────────────────────

// Accepted friends list.
router.get('/friends', authRequired, async (req, res) => {
  const [rows] = await pool.query(
    `SELECT ${MINI}
       FROM friendships f
       JOIN users u ON u.id = IF(f.requester_id = ?, f.addressee_id, f.requester_id)
      WHERE f.status = 'accepted' AND (f.requester_id = ? OR f.addressee_id = ?)
      ORDER BY u.full_name`,
    [req.user.id, req.user.id, req.user.id]
  );
  await applyPresenceVisibility(req.user.id, rows);
  res.json(rows);
});

// Incoming pending requests (people who asked to be my friend).
router.get('/friends/requests', authRequired, async (req, res) => {
  const [rows] = await pool.query(
    `SELECT ${MINI}, f.created_at
       FROM friendships f JOIN users u ON u.id = f.requester_id
      WHERE f.addressee_id = ? AND f.status = 'pending'
      ORDER BY f.created_at DESC`,
    [req.user.id]
  );
  await applyPresenceVisibility(req.user.id, rows);
  res.json(rows);
});

// Send a friend request (auto-accepts if the other side already requested me).
router.post('/friends/:userId', authRequired, async (req, res) => {
  const other = parseTarget(req, res);
  if (other == null) return;
  const [u] = await pool.query('SELECT id FROM users WHERE id = ?', [other]);
  if (!u.length) return res.status(404).json({ error: 'user not found' });
  if (await isBlockedEitherWay(req.user.id, other)) {
    return res.status(403).json({ error: 'blocked' });
  }
  const existing = await friendshipBetween(req.user.id, other);
  if (existing) {
    if (existing.status === 'accepted') return res.json({ friend_status: 'friends' });
    if (existing.requester_id === req.user.id) return res.json({ friend_status: 'outgoing' });
    // They already requested me → accept.
    await pool.query("UPDATE friendships SET status = 'accepted' WHERE id = ?", [existing.id]);
    notifyAccept(req, other);
    // Becoming friends opens a DM right away (best-effort).
    ensureDirectConversation(req.user.id, other)
      .catch((e) => console.error('[dm] auto-create failed:', e.message));
    return res.json({ friend_status: 'friends' });
  }
  await pool.query(
    "INSERT INTO friendships (requester_id, addressee_id, status) VALUES (?, ?, 'pending')",
    [req.user.id, other]
  );
  const name = await userName(req.user.id);
  createNotification(req.app.get('io'), {
    userId: other,
    type: 'friend_request',
    title: `${name} t'a envoyé une demande d'ami`,
    linkType: 'friends',
    linkId: req.user.id,
  }).catch((e) => console.error('[notif] friend_request failed:', e.message));
  res.status(201).json({ friend_status: 'outgoing' });
});

// Accept an incoming request.
router.post('/friends/:userId/accept', authRequired, async (req, res) => {
  const other = parseTarget(req, res);
  if (other == null) return;
  const [r] = await pool.query(
    "UPDATE friendships SET status = 'accepted' WHERE requester_id = ? AND addressee_id = ? AND status = 'pending'",
    [other, req.user.id]
  );
  if (!r.affectedRows) return res.status(400).json({ error: 'no pending request' });
  notifyAccept(req, other);
  // Becoming friends opens a DM right away (best-effort).
  ensureDirectConversation(req.user.id, other)
    .catch((e) => console.error('[dm] auto-create failed:', e.message));
  res.json({ friend_status: 'friends' });
});

// Cancel an outgoing request, decline an incoming one, or unfriend.
router.delete('/friends/:userId', authRequired, async (req, res) => {
  const other = parseTarget(req, res);
  if (other == null) return;
  await pool.query(
    `DELETE FROM friendships
      WHERE (requester_id = ? AND addressee_id = ?)
         OR (requester_id = ? AND addressee_id = ?)`,
    [req.user.id, other, other, req.user.id]
  );
  res.json({ friend_status: 'none' });
});

function notifyAccept(req, requesterId) {
  userName(req.user.id).then((name) =>
    createNotification(req.app.get('io'), {
      userId: requesterId,
      type: 'friend_accept',
      title: `${name} a accepté ta demande d'ami`,
      linkType: 'friends',
      linkId: req.user.id,
    })
  ).catch((e) => console.error('[notif] friend_accept failed:', e.message));
}

// ── Blocking ───────────────────────────────────────────────────────────────

router.get('/blocks', authRequired, async (req, res) => {
  const [rows] = await pool.query(
    `SELECT ${MINI} FROM blocks b JOIN users u ON u.id = b.blocked_id
      WHERE b.blocker_id = ? ORDER BY u.full_name`,
    [req.user.id]
  );
  res.json(rows);
});

router.post('/users/:userId/block', authRequired, async (req, res) => {
  const other = parseTarget(req, res);
  if (other == null) return;
  const [u] = await pool.query('SELECT id FROM users WHERE id = ?', [other]);
  if (!u.length) return res.status(404).json({ error: 'user not found' });
  await pool.query(
    'INSERT IGNORE INTO blocks (blocker_id, blocked_id) VALUES (?, ?)',
    [req.user.id, other]
  );
  // Blocking also severs any friendship/request between the two.
  await pool.query(
    `DELETE FROM friendships
      WHERE (requester_id = ? AND addressee_id = ?)
         OR (requester_id = ? AND addressee_id = ?)`,
    [req.user.id, other, other, req.user.id]
  );
  res.json({ blocked: true, friend_status: 'none' });
});

router.delete('/users/:userId/block', authRequired, async (req, res) => {
  const other = parseTarget(req, res);
  if (other == null) return;
  await pool.query(
    'DELETE FROM blocks WHERE blocker_id = ? AND blocked_id = ?',
    [req.user.id, other]
  );
  res.json({ blocked: false });
});

// ── Reporting ────────────────────────────────────────────────────────────────

router.post('/users/:userId/report', authRequired, async (req, res) => {
  const other = parseTarget(req, res);
  if (other == null) return;
  const reason = String(req.body?.reason ?? '').trim().slice(0, 60) || 'other';
  const details = String(req.body?.details ?? '').trim().slice(0, 2000);
  const [u] = await pool.query('SELECT id, full_name FROM users WHERE id = ?', [other]);
  if (!u.length) return res.status(404).json({ error: 'user not found' });
  await pool.query(
    'INSERT INTO reports (reporter_id, reported_user_id, reason, details) VALUES (?, ?, ?, ?)',
    [req.user.id, other, reason, details]
  );
  const [me] = await pool.query('SELECT full_name, email FROM users WHERE id = ?', [req.user.id]);
  sendAbuseReport({
    reportedName: u[0].full_name,
    reportedId: other,
    reporterName: me[0].full_name,
    reporterEmail: me[0].email,
    reason,
    details,
  }).catch((e) => console.error('[mail] abuse-report failed:', e.message));
  res.status(201).json({ reported: true });
});

module.exports = router;
module.exports.relationship = relationship;
module.exports.isBlockedEitherWay = isBlockedEitherWay;
