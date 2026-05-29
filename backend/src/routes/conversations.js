const express = require('express');
const pool = require('../config/db');
const { authRequired } = require('../middleware/auth');
const { userInConversation, createMessage } = require('../services/chat');
const { notifyNewMessage } = require('../services/notifications');

const router = express.Router();

router.get('/', authRequired, async (req, res) => {
  const [rows] = await pool.query(
    `SELECT c.id, c.type, c.project_id, c.created_at,
            p.title AS project_title,
            other.id AS other_user_id,
            other.full_name AS other_user_name,
            (SELECT content FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) AS last_message,
            (SELECT MAX(created_at) FROM messages WHERE conversation_id = c.id) AS last_message_at
       FROM conversations c
       JOIN conversation_members cm ON cm.conversation_id = c.id AND cm.user_id = ?
       LEFT JOIN projects p ON p.id = c.project_id
       LEFT JOIN conversation_members cm2 ON cm2.conversation_id = c.id AND cm2.user_id != ?
       LEFT JOIN users other ON other.id = cm2.user_id AND c.type = 'direct'
      ORDER BY last_message_at DESC, c.created_at DESC`,
    [req.user.id, req.user.id]
  );
  res.json(rows);
});

router.post('/direct/:userId', authRequired, async (req, res) => {
  const other = Number(req.params.userId);
  if (!other || other === req.user.id) {
    return res.status(400).json({ error: 'invalid target user' });
  }

  const [users] = await pool.query('SELECT id FROM users WHERE id = ?', [other]);
  if (!users.length) return res.status(404).json({ error: 'user not found' });

  const [existing] = await pool.query(
    `SELECT c.id
       FROM conversations c
       JOIN conversation_members a ON a.conversation_id = c.id AND a.user_id = ?
       JOIN conversation_members b ON b.conversation_id = c.id AND b.user_id = ?
      WHERE c.type = 'direct'
      LIMIT 1`,
    [req.user.id, other]
  );
  if (existing.length) return res.json({ id: existing[0].id, type: 'direct' });

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
    res.status(201).json({ id, type: 'direct' });
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

  let sql = `SELECT m.id, m.sender_id, u.full_name AS sender_name, m.content, m.created_at
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
  res.json(rows.reverse());
});

router.post('/:id/messages', authRequired, async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: 'invalid conversation id' });
  try {
    const msg = await createMessage(id, req.user.id, req.body?.content);
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

module.exports = router;
