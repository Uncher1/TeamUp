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

async function createMessage(conversationId, senderId, rawContent, attachment, attachmentsInput) {
  const id = Number(conversationId);
  if (!id) throw httpError(400, 'invalid conversation id');

  const content = (typeof rawContent === 'string' ? rawContent : '').trim();

  // Multi-attachment (images/files): up to 10, total payload capped.
  let attachments = null;
  if (Array.isArray(attachmentsInput) && attachmentsInput.length) {
    const list = [];
    let total = 0;
    for (const a of attachmentsInput.slice(0, 10)) {
      const type = ['image', 'file'].includes(a?.type) ? a.type : null;
      const data = typeof a?.data === 'string' ? a.data : '';
      if (!type || !data) continue;
      total += data.length;
      list.push({ type, name: String(a.name || '').slice(0, 255) || null, data });
    }
    if (total > MAX_ATTACHMENT_CHARS) throw httpError(413, 'attachments too large');
    if (list.length) attachments = list;
  }

  // Single attachment: audio (voice notes), a GIF (a remote URL, not bytes), or
  // a legacy single image/file.
  let att = null;
  if (!attachments && attachment && typeof attachment === 'object') {
    const type = ['image', 'file', 'audio', 'gif'].includes(attachment.type) ? attachment.type : null;
    const data = typeof attachment.data === 'string' ? attachment.data : '';
    if (type && data) {
      if (data.length > MAX_ATTACHMENT_CHARS) throw httpError(413, 'attachment too large');
      att = { type, name: String(attachment.name || '').slice(0, 255) || null, data };
    }
  }

  if (!content && !att && !attachments) throw httpError(400, 'content or attachment is required');
  if (content.length > 4000) throw httpError(400, 'content too long');

  if (!(await userInConversation(id, senderId))) {
    throw httpError(403, 'not a conversation member');
  }

  const [r] = await pool.query(
    `INSERT INTO messages (conversation_id, sender_id, content,
        attachment_type, attachment_name, attachment_data, attachments)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [id, senderId, content, att?.type ?? null, att?.name ?? null, att?.data ?? null,
     attachments ? JSON.stringify(attachments) : null]
  );
  const [rows] = await pool.query(
    `SELECT m.id, m.conversation_id, m.sender_id, u.full_name AS sender_name,
            u.role AS sender_role, m.content,
            m.attachment_type, m.attachment_name, m.attachment_data, m.attachments,
            m.edited, m.created_at
       FROM messages m JOIN users u ON u.id = m.sender_id
      WHERE m.id = ?`,
    [r.insertId]
  );
  return rows[0];
}

/**
 * Returns the id of the direct (1:1) conversation between two users, creating it
 * if it doesn't exist yet. Used when two people become friends so a DM is ready
 * immediately. Returns null for invalid/self pairs.
 */
async function ensureDirectConversation(userA, userB) {
  const a = Number(userA), b = Number(userB);
  if (!a || !b || a === b) return null;
  const [existing] = await pool.query(
    `SELECT c.id FROM conversations c
       JOIN conversation_members x ON x.conversation_id = c.id AND x.user_id = ?
       JOIN conversation_members y ON y.conversation_id = c.id AND y.user_id = ?
      WHERE c.type = 'direct' LIMIT 1`,
    [a, b]
  );
  if (existing.length) return existing[0].id;
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [r] = await conn.query("INSERT INTO conversations (type) VALUES ('direct')");
    const id = r.insertId;
    await conn.query(
      'INSERT INTO conversation_members (conversation_id, user_id) VALUES (?, ?), (?, ?)',
      [id, a, id, b]
    );
    await conn.commit();
    return id;
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
}

module.exports = { userInConversation, createMessage, ensureDirectConversation };
