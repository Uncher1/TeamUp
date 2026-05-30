const pool = require('../config/db');
const { getSettings, enabled } = require('./settings');

/**
 * Persists a notification and pushes it in realtime to the recipient's
 * personal Socket.IO room (`user:<id>`). `io` may be null (e.g. from a script).
 */
async function createNotification(io, { userId, type, title, body = null, linkType = null, linkId = null }) {
  const s = await getSettings(userId);
  if (!enabled(s, 'allNotifications')) return null;
  const typeToggle = {
    message: 'pushMessages',
    team_join: 'pushTeamUpdates',
    application: 'pushProjectUpdates',
    project_update: 'pushProjectUpdates',
    team_invite: 'pushTeamUpdates',
    mention: 'pushMentions',
  }[type];
  if (typeToggle && !enabled(s, typeToggle)) return null;

  const [r] = await pool.query(
    `INSERT INTO notifications (user_id, type, title, body, link_type, link_id)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [userId, type, title, body, linkType, linkId]
  );
  const [rows] = await pool.query(
    'SELECT id, type, title, body, link_type, link_id, is_read, created_at FROM notifications WHERE id = ?',
    [r.insertId]
  );
  const notif = { ...rows[0], is_read: !!rows[0].is_read };
  if (io) io.to(`user:${userId}`).emit('notification:new', notif);
  return notif;
}

/**
 * Notifies every conversation member except the sender, skipping members who
 * are currently watching the thread live (joined the conversation room).
 */
async function notifyNewMessage(io, msg, senderId) {
  const [members] = await pool.query(
    'SELECT user_id FROM conversation_members WHERE conversation_id = ? AND user_id != ?',
    [msg.conversation_id, senderId]
  );
  let present = new Set();
  if (io) {
    const sockets = await io.in(`conversation:${msg.conversation_id}`).fetchSockets();
    present = new Set(sockets.map(s => s.userId));
  }
  for (const m of members) {
    if (present.has(m.user_id)) continue;
    await createNotification(io, {
      userId: m.user_id,
      type: 'message',
      title: `Nouveau message de ${msg.sender_name}`,
      body: (msg.content || '').slice(0, 120),
      linkType: 'conversation',
      linkId: msg.conversation_id,
    });
  }
}

module.exports = { createNotification, notifyNewMessage };
