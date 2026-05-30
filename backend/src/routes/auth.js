const crypto = require('crypto');
const express = require('express');
const { OAuth2Client } = require('google-auth-library');
const pool = require('../config/db');
const { hash, verify } = require('../utils/password');
const { sign } = require('../utils/jwt');
const { authRequired } = require('../middleware/auth');
const { sendVerificationCode } = require('../services/mailer');

const router = express.Router();
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const CODE_TTL_MS = 30 * 60 * 1000; // 30 minutes

// Generates an XXXX-XXXX verification code (uppercase letters + digits).
function generateCode() {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let raw = '';
  for (let i = 0; i < 8; i++) raw += alphabet[crypto.randomInt(alphabet.length)];
  return `${raw.slice(0, 4)}-${raw.slice(4)}`;
}

// Stores a freshly generated code on the user and e-mails it. Returns the code.
async function issueVerification(userId, email, name) {
  const code = generateCode();
  const expires = new Date(Date.now() + CODE_TTL_MS);
  await pool.query(
    'UPDATE users SET verification_code = ?, verification_expires = ?, email_verified = 0 WHERE id = ?',
    [code, expires, userId]
  );
  // Send asynchronously; failure to e-mail must not break the API response.
  sendVerificationCode({ to: email, code, name }).catch((e) =>
    console.error('[auth] verification e-mail failed:', e.message)
  );
  return code;
}

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
  await issueVerification(id, email, full_name);
  const token = sign({ sub: id, email });
  res.status(201).json({ token, user: { id, email, full_name, email_verified: false } });
});

router.post('/login', async (req, res) => {
  const email    = (req.body?.email    ?? '').trim().toLowerCase();
  const password = (req.body?.password ?? '');

  if (!email || !password) {
    return res.status(400).json({ error: 'email and password are required' });
  }

  const [rows] = await pool.query(
    'SELECT id, email, password_hash, full_name, email_verified FROM users WHERE email = ?',
    [email]
  );
  const user = rows[0];
  if (!user) return res.status(401).json({ error: 'invalid credentials' });

  const ok = await verify(password, user.password_hash);
  if (!ok) return res.status(401).json({ error: 'invalid credentials' });

  const token = sign({ sub: user.id, email: user.email });
  res.json({
    token,
    user: {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      email_verified: !!user.email_verified,
    },
  });
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
    'SELECT id, email, full_name, email_verified FROM users WHERE email = ?',
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
    const id = result.insertId;
    // Per product requirement, new sign-ups verify by e-mail code — including
    // Google ones. (Google e-mails are already verified by Google, so this is
    // technically redundant; flip the next line to skip it for Google.)
    await issueVerification(id, email, fullName);
    user = { id, email, full_name: fullName, email_verified: 0 };
  }

  const token = sign({ sub: user.id, email: user.email });
  res.json({
    token,
    user: {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      email_verified: !!user.email_verified,
    },
    isNew,
  });
});

// Confirms the e-mail verification code for the authenticated user.
router.post('/verify', authRequired, async (req, res) => {
  const code = (req.body?.code ?? '').trim().toUpperCase();
  if (!code) return res.status(400).json({ error: 'code is required' });

  const [rows] = await pool.query(
    'SELECT email_verified, verification_code, verification_expires FROM users WHERE id = ?',
    [req.user.id]
  );
  const u = rows[0];
  if (!u) return res.status(404).json({ error: 'user not found' });
  if (u.email_verified) return res.json({ verified: true });

  if (!u.verification_code || u.verification_code !== code) {
    return res.status(400).json({ error: 'code incorrect' });
  }
  if (u.verification_expires && new Date(u.verification_expires).getTime() < Date.now()) {
    return res.status(400).json({ error: 'code expiré, renvoie un nouveau code' });
  }

  await pool.query(
    'UPDATE users SET email_verified = 1, verification_code = NULL, verification_expires = NULL WHERE id = ?',
    [req.user.id]
  );
  res.json({ verified: true });
});

// Re-issues a fresh verification code to the authenticated user.
router.post('/resend', authRequired, async (req, res) => {
  const [rows] = await pool.query(
    'SELECT email, full_name, email_verified FROM users WHERE id = ?',
    [req.user.id]
  );
  const u = rows[0];
  if (!u) return res.status(404).json({ error: 'user not found' });
  if (u.email_verified) return res.json({ verified: true });

  await issueVerification(req.user.id, u.email, u.full_name);
  res.json({ sent: true });
});

module.exports = router;
