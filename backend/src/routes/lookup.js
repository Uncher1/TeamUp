// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const express = require('express');
const pool = require('../config/db');

const router = express.Router();

router.get('/skills', async (_req, res) => {
  const [rows] = await pool.query(
    'SELECT id, name, category FROM skills ORDER BY category, name'
  );
  res.json(rows);
});

router.get('/interests', async (_req, res) => {
  const [rows] = await pool.query(
    'SELECT id, name, category FROM interests ORDER BY category, name'
  );
  res.json(rows);
});

module.exports = router;
