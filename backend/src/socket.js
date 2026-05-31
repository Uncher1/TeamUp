// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const { Server } = require('socket.io');
const { verify } = require('./utils/jwt');
const { userInConversation, createMessage } = require('./services/chat');
const { notifyNewMessage } = require('./services/notifications');

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
          payload?.content
        );
        io.to(`conversation:${msg.conversation_id}`).emit('message:new', msg);
        await notifyNewMessage(io, msg, socket.userId);
        if (typeof ack === 'function') ack({ ok: true, message: msg });
      } catch (e) {
        if (typeof ack === 'function') ack({ error: e.message || 'send failed' });
      }
    });
  });

  return io;
}

module.exports = { initSocket };
