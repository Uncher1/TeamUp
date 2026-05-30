const crypto = require('crypto');
const express = require('express');
const { OAuth2Client } = require('google-auth-library');
const pool = require('../config/db');
const { hash, verify } = require('../utils/password');
const { sign } = require('../utils/jwt');

const router = express.Router();
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

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

// Sign in / sign up with Google. The client sends the GIS ID token; we verify
// it, then log the user in — or create the account if it's a new Google user.
router.post('/google', async (req, res) => {
  const idToken = req.body?.id_token ?? '';
  if (!idToken) return res.status(400).json({ error: 'id_token is required' });
  if (!process.env.GOOGLE_CLIENT_ID) {
    return res.status(500).json({ error: 'Google sign-in not configured' });
  }

  let payload;
  try {
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    payload = ticket.getPayload();
  } catch (e) {
    return res.status(401).json({ error: 'invalid Google token' });
  }

  const email = (payload?.email ?? '').trim().toLowerCase();
  if (!email) return res.status(400).json({ error: 'no email in Google token' });
  const fullName = (payload.name ?? email.split('@')[0]).slice(0, 120);

  const [rows] = await pool.query(
    'SELECT id, email, full_name FROM users WHERE email = ?',
    [email]
  );
  let user = rows[0];
  const isNew = !user;
  if (!user) {
    // New Google account → sign up. Password is random (account uses Google).
    const password_hash = await hash(crypto.randomBytes(24).toString('hex'));
    const [result] = await pool.query(
      'INSERT INTO users (email, password_hash, full_name) VALUES (?, ?, ?)',
      [email, password_hash, fullName]
    );
    user = { id: result.insertId, email, full_name: fullName };
  }

  const token = sign({ sub: user.id, email: user.email });
  res.json({
    token,
    user: { id: user.id, email: user.email, full_name: user.full_name },
    isNew,
  });
});

module.exports = router;
