// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const express = require('express');
const pool = require('../config/db');
const { authRequired } = require('../middleware/auth');
const { userInConversation, createMessage } = require('../services/chat');
const { notifyNewMessage } = require('../services/notifications');
const { getSettings, enabled } = require('../services/settings');
const { enrichPolls, pollPublic } = require('../services/polls');
const { isBlockedEitherWay } = require('./social');
const { applyPresenceVisibility, effectivePresence } = require('../services/presence');

const router = express.Router();

router.get('/', authRequired, async (req, res) => {
  const [rows] = await pool.query(
    `SELECT c.id, c.type, c.project_id, c.created_at,
            p.title AS project_title,
            p.avatar_url AS project_avatar,
            p.owner_id AS project_owner_id,
            other.id AS other_user_id,
            other.full_name AS other_user_name,
            other.avatar_url AS other_user_avatar,
            other.presence_status AS other_user_status,
            (SELECT content FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) AS last_message,
            (SELECT sender_id FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) AS last_sender_id,
            (SELECT attachment_type FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) AS last_attachment_type,
            (SELECT su.full_name FROM messages lm JOIN users su ON su.id = lm.sender_id
              WHERE lm.conversation_id = c.id ORDER BY lm.created_at DESC LIMIT 1) AS last_sender_name,
            (SELECT MAX(created_at) FROM messages WHERE conversation_id = c.id) AS last_message_at
       FROM conversations c
       JOIN conversation_members cm ON cm.conversation_id = c.id AND cm.user_id = ?
       LEFT JOIN projects p ON p.id = c.project_id
       LEFT JOIN conversation_members cm2 ON cm2.conversation_id = c.id AND cm2.user_id != ?
       LEFT JOIN users other ON other.id = cm2.user_id AND c.type = 'direct'
      WHERE c.type = 'project'
         OR EXISTS (SELECT 1 FROM messages msg WHERE msg.conversation_id = c.id)
      ORDER BY last_message_at DESC, c.created_at DESC`,
    [req.user.id, req.user.id]
  );
  await applyPresenceVisibility(req.user.id, rows,
    { idKey: 'other_user_id', statusKey: 'other_user_status' });
  res.json(rows);
});

router.post('/direct/:userId', authRequired, async (req, res) => {
  const other = Number(req.params.userId);
  if (!other || other === req.user.id) {
    return res.status(400).json({ error: 'invalid target user' });
  }

  const [users] = await pool.query(
    'SELECT id, full_name, avatar_url, presence_status FROM users WHERE id = ?', [other]);
  if (!users.length) return res.status(404).json({ error: 'user not found' });

  if (await isBlockedEitherWay(req.user.id, other)) {
    return res.status(403).json({ error: 'blocked' });
  }

  const targetSettings = await getSettings(other);
  if (!enabled(targetSettings, 'allowMessages')) {
    return res.status(403).json({ error: "Cet utilisateur n'accepte pas les messages." });
  }

  // Include the other person's identity so the chat header can show their
  // avatar + presence + name (no more "Conversation #X").
  const visibleStatus = await effectivePresence(req.user.id, other, users[0].presence_status);
  const otherInfo = {
    type: 'direct',
    other_user_id: other,
    other_user_name: users[0].full_name,
    other_user_avatar: users[0].avatar_url,
    other_user_status: visibleStatus,
  };

  const [existing] = await pool.query(
    `SELECT c.id
       FROM conversations c
       JOIN conversation_members a ON a.conversation_id = c.id AND a.user_id = ?
       JOIN conversation_members b ON b.conversation_id = c.id AND b.user_id = ?
      WHERE c.type = 'direct'
      LIMIT 1`,
    [req.user.id, other]
  );
  if (existing.length) return res.json({ id: existing[0].id, ...otherInfo });

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [r] = await conn.query("INSERT INTO conversations (type) VALUES ('direct')");
    const id = r.insertId;
    await conn.query(
      'INSERT INTO conversation_members (conversation_id, user_id) VALUES (?, ?), (?, ?)',
      [id, req.user.id, id, other]
    );
    await conn.commit();
    res.status(201).json({ id, ...otherInfo });
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
});

router.get('/:id/messages', authRequired, async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: 'invalid conversation id' });
  if (!(await userInConversation(id, req.user.id))) {
    return res.status(403).json({ error: 'not a conversation member' });
  }
  const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 50));
  const before = req.query.before ? new Date(req.query.before) : null;

  let sql = `SELECT m.id, m.sender_id, u.full_name AS sender_name, u.role AS sender_role,
                    m.content, m.attachment_type, m.attachment_name, m.attachment_data,
                    m.attachments, m.created_at
               FROM messages m JOIN users u ON u.id = m.sender_id
              WHERE m.conversation_id = ?`;
  const args = [id];
  if (before && !isNaN(before.getTime())) {
    sql += ' AND m.created_at < ?';
    args.push(before);
  }
  sql += ' ORDER BY m.created_at DESC LIMIT ?';
  args.push(limit);
  const [rows] = await pool.query(sql, args);
  await enrichPolls(rows, req.user.id);
  res.json(rows.reverse());
});

// Create a poll — TEAM (project) conversations only.
router.post('/:id/polls', authRequired, async (req, res) => {
  const id = Number(req.params.id);
  const question = String(req.body?.question ?? '').trim().slice(0, 300);
  const options = Array.isArray(req.body?.options)
    ? req.body.options.map((o) => String(o).trim()).filter(Boolean).slice(0, 6)
    : [];
  const multi = req.body?.multi ? 1 : 0;
  if (!id || !question || options.length < 2) {
    return res.status(400).json({ error: 'question and at least 2 options required' });
  }
  const [conv] = await pool.query('SELECT type FROM conversations WHERE id = ?', [id]);
  if (!conv.length) return res.status(404).json({ error: 'conversation not found' });
  if (conv[0].type !== 'project') {
    return res.status(400).json({ error: 'polls are only available in team conversations' });
  }
  if (!(await userInConversation(id, req.user.id))) {
    return res.status(403).json({ error: 'not a conversation member' });
  }
  const [pr] = await pool.query(
    'INSERT INTO polls (conversation_id, question, options, created_by, multi) VALUES (?, ?, ?, ?, ?)',
    [id, question, JSON.stringify(options), req.user.id, multi]
  );
  const pollId = pr.insertId;
  const [mr] = await pool.query(
    `INSERT INTO messages (conversation_id, sender_id, content, attachment_type, attachment_data)
     VALUES (?, ?, ?, 'poll', ?)`,
    [id, req.user.id, question, String(pollId)]
  );
  await pool.query('UPDATE polls SET message_id = ? WHERE id = ?', [mr.insertId, pollId]);
  const [rows] = await pool.query(
    `SELECT m.id, m.conversation_id, m.sender_id, u.full_name AS sender_name, u.role AS sender_role,
            m.content, m.attachment_type, m.attachment_name, m.attachment_data, m.created_at
       FROM messages m JOIN users u ON u.id = m.sender_id WHERE m.id = ?`,
    [mr.insertId]
  );
  const msg = rows[0];
  msg.poll = await pollPublic(pollId, req.user.id);
  const io = req.app.get('io');
  io?.to(`conversation:${id}`).emit('message:new', msg);
  res.status(201).json(msg);
});

// Vote (or change vote) on a poll.
router.post('/polls/:pollId/vote', authRequired, async (req, res) => {
  const pollId = Number(req.params.pollId);
  const option = Number(req.body?.option);
  if (!pollId || Number.isNaN(option)) {
    return res.status(400).json({ error: 'pollId and option are required' });
  }
  const [pr] = await pool.query(
    'SELECT conversation_id, options, multi FROM polls WHERE id = ?', [pollId]);
  if (!pr.length) return res.status(404).json({ error: 'poll not found' });
  const convId = pr[0].conversation_id;
  if (!(await userInConversation(convId, req.user.id))) {
    return res.status(403).json({ error: 'not a conversation member' });
  }
  let optionsLen = 0;
  try { optionsLen = JSON.parse(pr[0].options).length; } catch { optionsLen = 0; }
  if (option < 0 || option >= optionsLen) return res.status(400).json({ error: 'invalid option' });

  if (pr[0].multi === 1) {
    // Multi-choice: tapping an option toggles it on/off.
    const [ex] = await pool.query(
      'SELECT 1 AS x FROM poll_votes WHERE poll_id = ? AND user_id = ? AND option_index = ?',
      [pollId, req.user.id, option]);
    if (ex.length) {
      await pool.query(
        'DELETE FROM poll_votes WHERE poll_id = ? AND user_id = ? AND option_index = ?',
        [pollId, req.user.id, option]);
    } else {
      await pool.query(
        'INSERT INTO poll_votes (poll_id, user_id, option_index) VALUES (?, ?, ?)',
        [pollId, req.user.id, option]);
    }
  } else {
    // Single-choice: the new pick replaces any previous one.
    await pool.query(
      'DELETE FROM poll_votes WHERE poll_id = ? AND user_id = ?', [pollId, req.user.id]);
    await pool.query(
      'INSERT INTO poll_votes (poll_id, user_id, option_index) VALUES (?, ?, ?)',
      [pollId, req.user.id, option]);
  }
  const poll = await pollPublic(pollId, req.user.id);
  const io = req.app.get('io');
  io?.to(`conversation:${convId}`).emit('poll:update', poll);
  res.json(poll);
});

router.post('/:id/messages', authRequired, async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: 'invalid conversation id' });
  try {
    const msg = await createMessage(
      id, req.user.id, req.body?.content, req.body?.attachment, req.body?.attachments);
    const io = req.app.get('io');
    // Mirror the message to any socket clients watching this conversation.
    io?.to(`conversation:${id}`).emit('message:new', msg);
    await notifyNewMessage(io, msg, req.user.id);
    res.status(201).json(msg);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ error: e.message });
    throw e;
  }
});

// Edit your own (text) message.
router.patch('/:id/messages/:mid', authRequired, async (req, res) => {
  const id = Number(req.params.id);
  const mid = Number(req.params.mid);
  const content = String(req.body?.content ?? '').trim().slice(0, 4000);
  if (!id || !mid) return res.status(400).json({ error: 'invalid id' });
  if (!content) return res.status(400).json({ error: 'content is required' });
  const [rows] = await pool.query(
    'SELECT sender_id, attachment_type FROM messages WHERE id = ? AND conversation_id = ?',
    [mid, id]
  );
  if (!rows.length) return res.status(404).json({ error: 'message not found' });
  if (rows[0].sender_id !== req.user.id) return res.status(403).json({ error: 'not your message' });
  if (rows[0].attachment_type) return res.status(400).json({ error: 'only text messages can be edited' });
  await pool.query('UPDATE messages SET content = ? WHERE id = ?', [content, mid]);
  req.app.get('io')?.to(`conversation:${id}`).emit('message:update', {
    id: mid, conversation_id: id, content,
  });
  res.json({ id: mid, content });
});

// Delete a message: the author, or — in a team (project) chat — the team owner.
router.delete('/:id/messages/:mid', authRequired, async (req, res) => {
  const id = Number(req.params.id);
  const mid = Number(req.params.mid);
  if (!id || !mid) return res.status(400).json({ error: 'invalid id' });
  const [rows] = await pool.query(
    'SELECT sender_id FROM messages WHERE id = ? AND conversation_id = ?', [mid, id]);
  if (!rows.length) return res.status(404).json({ error: 'message not found' });
  let allowed = rows[0].sender_id === req.user.id;
  if (!allowed) {
    const [c] = await pool.query(
      `SELECT p.owner_id FROM conversations c JOIN projects p ON p.id = c.project_id
        WHERE c.id = ? AND c.type = 'project'`, [id]);
    if (c.length && c[0].owner_id === req.user.id) allowed = true;
  }
  if (!allowed) return res.status(403).json({ error: 'not allowed' });
  await pool.query('DELETE FROM messages WHERE id = ?', [mid]);
  req.app.get('io')?.to(`conversation:${id}`).emit('message:delete', {
    id: mid, conversation_id: id,
  });
  res.json({ deleted: true });
});

module.exports = router;
