// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

// Presence visibility (WhatsApp-style): a user's `presenceVisibility` setting
// ('everyone' | 'friends' | 'nobody', default 'everyone') controls who may see
// their online status. When a viewer isn't allowed, we report 'offline' so the
// real status (online/dnd) stays private.
const pool = require('../config/db');

async function visibilityFor(ids) {
  const map = new Map();
  if (!ids.length) return map;
  const [rows] = await pool.query(
    `SELECT user_id, setting_value FROM user_settings
      WHERE setting_key = 'presenceVisibility' AND user_id IN (?)`,
    [ids]
  );
  for (const r of rows) map.set(r.user_id, r.setting_value);
  return map;
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
  const vis = await visibilityFor(targets);
  const friends = await friendIdsAmong(viewerId, targets);
  for (const r of rows) {
    const id = r[idKey];
    if (!id || id === viewerId) continue;
    const v = vis.get(id) || 'everyone';
    if (v === 'nobody' || (v === 'friends' && !friends.has(id))) {
      r[statusKey] = 'offline';
    }
  }
  return rows;
}

/// Single-user variant: returns the status the [viewerId] is allowed to see.
async function effectivePresence(viewerId, targetId, status) {
  if (!targetId || targetId === viewerId) return status;
  const vis = await visibilityFor([targetId]);
  const v = vis.get(targetId) || 'everyone';
  if (v === 'everyone') return status;
  if (v === 'nobody') return 'offline';
  const friends = await friendIdsAmong(viewerId, [targetId]);
  return friends.has(targetId) ? status : 'offline';
}

module.exports = { applyPresenceVisibility, effectivePresence };
