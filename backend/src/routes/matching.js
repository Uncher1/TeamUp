// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const express = require('express');
const { authRequired } = require('../middleware/auth');
const matching = require('../services/matching');
const { getSettings, enabled } = require('../services/settings');
const { applyPresenceVisibility } = require('../services/presence');

const router = express.Router();

const clampLimit = (q) => Math.min(50, Math.max(1, Number(q) || 10));

router.get('/projects/:id/users', authRequired, async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: 'invalid project id' });
  const result = await matching.rankUsersForProject(id, clampLimit(req.query.limit));
  const filtered = [];
  for (const u of result) {
    const s = await getSettings(u.user_id);
    if (enabled(s, 'appearInSearch')) filtered.push(u);
  }
  await applyPresenceVisibility(req.user.id, filtered, { idKey: 'user_id' });
  res.json(filtered);
});

router.get('/users/me/projects', authRequired, async (req, res) => {
  const result = await matching.rankProjectsForUser(req.user.id, clampLimit(req.query.limit));
  res.json(result);
});

module.exports = router;
