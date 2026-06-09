// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

// Presence visibility (WhatsApp-style): a user's `presenceVisibility` setting
// ('everyone' | 'friends' | 'nobody', default 'everyone') controls who may see
// their online status. When a viewer isn't allowed, we report 'offline' so the
// real status (online/dnd) stays private.
const pool = require('../config/db');
const { isOnline } = require('./onlineTracker');

// Per-user { visibility: 'everyone'|'friends'|'nobody', online: bool } where
// `online` reflects the privacy-tab "show online status" toggle (default true).
async function settingsFor(ids) {
  const map = new Map();
  if (!ids.length) return map;
  const [rows] = await pool.query(
    `SELECT user_id, setting_key, setting_value FROM user_settings
      WHERE setting_key IN ('presenceVisibility', 'showOnlineStatus') AND user_id IN (?)`,
    [ids]
  );
  for (const r of rows) {
    const e = map.get(r.user_id) || { visibility: 'everyone', online: true };
    if (r.setting_key === 'presenceVisibility') e.visibility = r.setting_value;
    if (r.setting_key === 'showOnlineStatus') e.online = r.setting_value !== 'false';
    map.set(r.user_id, e);
  }
  return map;
}

function _cfg(map, id) {
  return map.get(id) || { visibility: 'everyone', online: true };
}

async function friendIdsAmong(viewerId, ids) {
  if (!ids.length) return new Set();
  const [rows] = await pool.query(
    `SELECT IF(requester_id = ?, addressee_id, requester_id) AS fid
       FROM friendships
      WHERE status = 'accepted'
        AND ((requester_id = ? AND addressee_id IN (?))
          OR (addressee_id = ? AND requester_id IN (?)))`,
    [viewerId, viewerId, ids, viewerId, ids]
  );
  return new Set(rows.map((r) => r.fid));
}

/// Mutates [rows] in place: hides (→ 'offline') the presence of users the viewer
/// is not allowed to see. [idKey]/[statusKey] name the fields on each row.
async function applyPresenceVisibility(viewerId, rows, { idKey = 'id', statusKey = 'presence_status' } = {}) {
  const targets = [...new Set(rows.map((r) => r[idKey]).filter((id) => id && id !== viewerId))];
  if (!targets.length) return rows;
  const cfg = await settingsFor(targets);
  const friends = await friendIdsAmong(viewerId, targets);
  for (const r of rows) {
    const id = r[idKey];
    if (!id || id === viewerId) continue;
    // Real connectivity drives online/offline; a disconnected user is offline
    // whatever their stored status. A connected user keeps their manual status
    // (online / dnd, or offline if they chose invisible mode).
    if (!isOnline(id)) { r[statusKey] = 'offline'; continue; }
    const { visibility, online } = _cfg(cfg, id);
    const hidden = !online ||
        visibility === 'nobody' ||
        (visibility === 'friends' && !friends.has(id));
    if (hidden) r[statusKey] = 'offline';
  }
  return rows;
}

/// Single-user variant: returns the status the [viewerId] is allowed to see.
async function effectivePresence(viewerId, targetId, status) {
  if (!targetId || targetId === viewerId) return status;
  if (!isOnline(targetId)) return 'offline';
  const cfg = await settingsFor([targetId]);
  const { visibility, online } = _cfg(cfg, targetId);
  if (!online || visibility === 'nobody') return 'offline';
  if (visibility === 'everyone') return status;
  const friends = await friendIdsAmong(viewerId, [targetId]);
  return friends.has(targetId) ? status : 'offline';
}

module.exports = { applyPresenceVisibility, effectivePresence };
