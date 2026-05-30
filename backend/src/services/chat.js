const pool = require('../config/db');

/** Throwable carrying an HTTP-ish status so REST and socket layers can map it. */
function httpError(status, message) {
  const e = new Error(message);
  e.status = status;
  return e;
}

async function userInConversation(conversationId, userId) {
  const [rows] = await pool.query(
    'SELECT 1 AS x FROM conversation_members WHERE conversation_id = ? AND user_id = ?',
    [conversationId, userId]
  );
  return rows.length > 0;
}

/**
 * Validates, persists and returns a chat message (with the sender's name and
 * the real DB timestamp). Shared by the REST endpoint and the Socket.IO layer.
 */
async function createMessage(conversationId, senderId, rawContent) {
  const id = Number(conversationId);
  if (!id) throw httpError(400, 'invalid conversation id');

  const content = (typeof rawContent === 'string' ? rawContent : '').trim();
  if (!content) throw httpError(400, 'content is required');
  if (content.length > 4000) throw httpError(400, 'content too long');

  if (!(await userInConversation(id, senderId))) {
    throw httpError(403, 'not a conversation member');
  }

  const [r] = await pool.query(
    'INSERT INTO messages (conversation_id, sender_id, content) VALUES (?, ?, ?)',
    [id, senderId, content]
  );
  const [rows] = await pool.query(
    `SELECT m.id, m.conversation_id, m.sender_id, u.full_name AS sender_name,
            u.role AS sender_role, m.content, m.created_at
       FROM messages m JOIN users u ON u.id = m.sender_id
      WHERE m.id = ?`,
    [r.insertId]
  );
  return rows[0];
}

module.exports = { userInConversation, createMessage };
