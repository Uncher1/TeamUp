// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

// Live presence: how many open sockets each user currently has. The app runs as
// a single Node process (REST routes + Socket.IO share this module in-memory),
// so this is the source of truth for "is this user actually connected now".
// `presence_status` in the DB is only the user's MANUAL preference
// (online / dnd / offline-invisible); real online/offline is derived from here.
const counts = new Map();

function connect(userId) {
  const id = Number(userId);
  if (!id) return;
  counts.set(id, (counts.get(id) || 0) + 1);
}

function disconnect(userId) {
  const id = Number(userId);
  if (!id) return;
  const n = (counts.get(id) || 0) - 1;
  if (n <= 0) counts.delete(id);
  else counts.set(id, n);
}

function isOnline(userId) {
  return counts.has(Number(userId));
}

module.exports = { connect, disconnect, isOnline };
