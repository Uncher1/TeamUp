// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

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
// Max base64 length for an attachment (~5.5 MB of binary). Keeps the DB and
// payloads sane on a phone-first, free-tier app.
const MAX_ATTACHMENT_CHARS = 7_500_000;

async function createMessage(conversationId, senderId, rawContent, attachment) {
  const id = Number(conversationId);
  if (!id) throw httpError(400, 'invalid conversation id');

  const content = (typeof rawContent === 'string' ? rawContent : '').trim();

  // Optional attachment: { type: 'image'|'file', name, data (base64 data URL) }.
  let att = null;
  if (attachment && typeof attachment === 'object') {
    const type = ['image', 'file', 'audio'].includes(attachment.type) ? attachment.type : null;
    const data = typeof attachment.data === 'string' ? attachment.data : '';
    if (type && data) {
      if (data.length > MAX_ATTACHMENT_CHARS) throw httpError(413, 'attachment too large');
      att = { type, name: String(attachment.name || '').slice(0, 255) || null, data };
    }
  }

  if (!content && !att) throw httpError(400, 'content or attachment is required');
  if (content.length > 4000) throw httpError(400, 'content too long');

  if (!(await userInConversation(id, senderId))) {
    throw httpError(403, 'not a conversation member');
  }

  const [r] = await pool.query(
    `INSERT INTO messages (conversation_id, sender_id, content,
        attachment_type, attachment_name, attachment_data)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [id, senderId, content, att?.type ?? null, att?.name ?? null, att?.data ?? null]
  );
  const [rows] = await pool.query(
    `SELECT m.id, m.conversation_id, m.sender_id, u.full_name AS sender_name,
            u.role AS sender_role, m.content,
            m.attachment_type, m.attachment_name, m.attachment_data, m.created_at
       FROM messages m JOIN users u ON u.id = m.sender_id
      WHERE m.id = ?`,
    [r.insertId]
  );
  return rows[0];
}

module.exports = { userInConversation, createMessage };
