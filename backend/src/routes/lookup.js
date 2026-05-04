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
    'SELECT id, name FROM interests ORDER BY name'
  );
  res.json(rows);
});

module.exports = router;
