const express = require('express');
const pool = require('../config/db');
const { hash, verify } = require('../utils/password');
const { sign } = require('../utils/jwt');

const router = express.Router();

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

router.post('/register', async (req, res) => {
  const email     = (req.body?.email     ?? '').trim().toLowerCase();
  const password  = (req.body?.password  ?? '');
  const full_name = (req.body?.full_name ?? '').trim();

  if (!email || !password || !full_name) {
    return res.status(400).json({ error: 'email, password and full_name are required' });
  }
  if (!EMAIL_RE.test(email)) {
    return res.status(400).json({ error: 'invalid email format' });
  }
  if (password.length < 8) {
    return res.status(400).json({ error: 'password must be at least 8 characters' });
  }
  if (full_name.length > 120) {
    return res.status(400).json({ error: 'full_name is too long' });
  }

  const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
  if (existing.length) {
    return res.status(409).json({ error: 'email already registered' });
  }

  const password_hash = await hash(password);
  const [result] = await pool.query(
    'INSERT INTO users (email, password_hash, full_name) VALUES (?, ?, ?)',
    [email, password_hash, full_name]
  );
  const id = result.insertId;
  const token = sign({ sub: id, email });
  res.status(201).json({ token, user: { id, email, full_name } });
});

router.post('/login', async (req, res) => {
  const email    = (req.body?.email    ?? '').trim().toLowerCase();
  const password = (req.body?.password ?? '');

  if (!email || !password) {
    return res.status(400).json({ error: 'email and password are required' });
  }

  const [rows] = await pool.query(
    'SELECT id, email, password_hash, full_name FROM users WHERE email = ?',
    [email]
  );
  const user = rows[0];
  if (!user) return res.status(401).json({ error: 'invalid credentials' });

  const ok = await verify(password, user.password_hash);
  if (!ok) return res.status(401).json({ error: 'invalid credentials' });

  const token = sign({ sub: user.id, email: user.email });
  res.json({ token, user: { id: user.id, email: user.email, full_name: user.full_name } });
});

module.exports = router;
