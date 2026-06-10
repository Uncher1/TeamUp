// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const { Server } = require('socket.io');
const pool = require('./config/db');
const { verify } = require('./utils/jwt');
const { userInConversation, createMessage } = require('./services/chat');
const { notifyNewMessage } = require('./services/notifications');
const onlineTracker = require('./services/onlineTracker');

/**
 * Attaches a Socket.IO server to an existing HTTP server.
 *
 * Auth: the client sends its JWT in the handshake (`auth.token`). Clients join
 * per-conversation rooms (`conversation:<id>`) after a membership check, then
 * `message:send` persists via the shared chat service and broadcasts
 * `message:new` to everyone in the room (sender included).
 */
function initSocket(server) {
  const io = new Server(server, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
  });

  io.use((socket, next) => {
    const token =
      socket.handshake.auth?.token ||
      (socket.handshake.headers.authorization || '').split(' ')[1];
    if (!token) return next(new Error('missing token'));
    try {
      const payload = verify(token);
      socket.userId = payload.sub;
      socket.userEmail = payload.email;
      next();
    } catch {
      next(new Error('invalid or expired token'));
    }
  });

  io.on('connection', (socket) => {
    socket.join(`user:${socket.userId}`);
    // Track real connectivity so presence reflects actual activity, not just the
    // stored manual status. We do NOT broadcast a presence event here: the REST
    // endpoints already compute each viewer's allowed view via the presence
    // visibility rules (effectivePresence/applyPresenceVisibility), and a global
    // broadcast would leak online/offline past those rules. Clients pick up the
    // change on their next fetch/refresh.
    onlineTracker.connect(socket.userId);

    socket.on('disconnect', () => {
      onlineTracker.disconnect(socket.userId);
    });

    socket.on('conversation:join', async (conversationId, ack) => {
      const id = Number(conversationId);
      if (!id) return typeof ack === 'function' && ack({ error: 'invalid conversation id' });
      try {
        if (!(await userInConversation(id, socket.userId))) {
          return typeof ack === 'function' && ack({ error: 'not a conversation member' });
        }
        socket.join(`conversation:${id}`);
        if (typeof ack === 'function') ack({ ok: true });
      } catch (e) {
        if (typeof ack === 'function') ack({ error: 'join failed' });
      }
    });

    socket.on('conversation:leave', (conversationId) => {
      const id = Number(conversationId);
      if (id) socket.leave(`conversation:${id}`);
    });

    socket.on('message:send', async (payload, ack) => {
      try {
        const msg = await createMessage(
          payload?.conversationId,
          socket.userId,
          payload?.content,
          payload?.attachment,
          payload?.attachments
        );
        io.to(`conversation:${msg.conversation_id}`).emit('message:new', msg);
        await notifyNewMessage(io, msg, socket.userId);
        if (typeof ack === 'function') ack({ ok: true, message: msg });
      } catch (e) {
        if (typeof ack === 'function') ack({ error: e.message || 'send failed' });
      }
    });

    // ── 1:1 call signaling (WebRTC) ──────────────────────────────────────────
    // All events are relayed to the target user's personal room (`user:<id>`).
    // `from` is always set server-side to the authenticated sender (no spoofing).
    const toUser = (id) => `user:${Number(id)}`;

    // Caller rings callee: enrich with the caller's name/avatar for the popup.
    socket.on('call:invite', async (p) => {
      const to = Number(p?.to);
      if (!to || to === socket.userId) return;
      let name = '', avatar = null;
      try {
        const [r] = await pool.query('SELECT full_name, avatar_url FROM users WHERE id = ?', [socket.userId]);
        if (r.length) { name = r[0].full_name; avatar = r[0].avatar_url; }
      } catch { /* best-effort */ }
      console.log(`[call] invite ${socket.userId} → ${to} (${p?.callType})`);
      io.to(toUser(to)).emit('call:incoming', {
        from: socket.userId,
        fromName: name,
        fromAvatar: avatar,
        callType: p?.callType === 'audio' ? 'audio' : 'video',
        conversationId: p?.conversationId ?? null,
      });
    });

    // Relay the rest verbatim (with a trusted `from`).
    const relay = (event, outEvent) => socket.on(event, (p) => {
      const to = Number(p?.to);
      if (!to) return;
      let extra = '';
      if (event === 'call:ice') {
        const m = (p?.candidate?.candidate || '').match(/ typ (\w+)/);
        extra = m ? ` [${m[1]}]` : ' [?]'; // host / srflx / relay(=TURN) / prflx
      }
      console.log(`[call] ${event} ${socket.userId} → ${to}${extra}`);
      io.to(toUser(to)).emit(outEvent, { ...p, to: undefined, from: socket.userId });
    });
    relay('call:cancel', 'call:cancelled');
    relay('call:accept', 'call:accepted');
    relay('call:reject', 'call:rejected');
    relay('call:offer', 'call:offer');
    relay('call:answer', 'call:answer');
    relay('call:ice', 'call:ice');
    relay('call:media', 'call:media');
    relay('call:end', 'call:ended');
  });

  return io;
}

module.exports = { initSocket };
