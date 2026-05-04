const express = require('express');
const { authRequired } = require('../middleware/auth');
const matching = require('../services/matching');

const router = express.Router();

const clampLimit = (q) => Math.min(50, Math.max(1, Number(q) || 10));

router.get('/projects/:id/users', authRequired, async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: 'invalid project id' });
  const result = await matching.rankUsersForProject(id, clampLimit(req.query.limit));
  res.json(result);
});

router.get('/users/me/projects', authRequired, async (req, res) => {
  const result = await matching.rankProjectsForUser(req.user.id, clampLimit(req.query.limit));
  res.json(result);
});

module.exports = router;
