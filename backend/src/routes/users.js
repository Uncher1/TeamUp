const express = require('express');
const pool = require('../config/db');
const { authRequired } = require('../middleware/auth');
const { hash, verify } = require('../utils/password');
const { getSettings, enabled } = require('../services/settings');
const { sendEmailChanged, sendPasswordChanged } = require('../services/mailer');
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const router = express.Router();

async function loadProfile(userId) {
  const [users] = await pool.query(
    `SELECT id, email, full_name, bio, avatar_url, created_at,
            phone, school, department, study_year, location,
            github, linkedin, twitter, website
       FROM users WHERE id = ?`,
    [userId]
  );
  if (!users.length) return null;
  const [skills] = await pool.query(
    `SELECT s.id, s.name, s.category, us.level
       FROM user_skills us JOIN skills s ON s.id = us.skill_id
      WHERE us.user_id = ?`,
    [userId]
  );
  const [interests] = await pool.query(
    `SELECT i.id, i.name
       FROM user_interests ui JOIN interests i ON i.id = ui.interest_id
      WHERE ui.user_id = ?`,
    [userId]
  );
  return { ...users[0], skills, interests };
}

router.get('/me', authRequired, async (req, res) => {
  const profile = await loadProfile(req.user.id);
  if (!profile) return res.status(404).json({ error: 'user not found' });
  res.json(profile);
});

router.patch('/me', authRequired, async (req, res) => {
  const { full_name, bio, avatar_url, email,
          phone, school, department, study_year, location,
          github, linkedin, twitter, website } = req.body || {};
  let oldEmail = null;
  let changedEmail = null;
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    if (email !== undefined) {
      const normalized = String(email).trim().toLowerCase();
      if (!EMAIL_RE.test(normalized)) {
        await conn.rollback();
        return res.status(400).json({ error: 'invalid email format' });
      }
      const [cur] = await conn.query('SELECT email FROM users WHERE id = ?', [req.user.id]);
      if (cur.length && cur[0].email !== normalized) {
        const [dup] = await conn.query('SELECT id FROM users WHERE email = ? AND id != ?', [normalized, req.user.id]);
        if (dup.length) {
          await conn.rollback();
          return res.status(409).json({ error: 'email already in use' });
        }
        await conn.query('UPDATE users SET email = ? WHERE id = ?', [normalized, req.user.id]);
        oldEmail = cur[0].email;
        changedEmail = normalized;
      }
    }
    await conn.query(
      `UPDATE users SET
          full_name  = COALESCE(?, full_name),
          bio        = COALESCE(?, bio),
          avatar_url = COALESCE(?, avatar_url),
          phone      = COALESCE(?, phone),
          school     = COALESCE(?, school),
          department = COALESCE(?, department),
          study_year = COALESCE(?, study_year),
          location   = COALESCE(?, location),
          github     = COALESCE(?, github),
          linkedin   = COALESCE(?, linkedin),
          twitter    = COALESCE(?, twitter),
          website    = COALESCE(?, website)
        WHERE id = ?`,
      [full_name ?? null, bio ?? null, avatar_url ?? null,
       phone ?? null, school ?? null, department ?? null, study_year ?? null, location ?? null,
       github ?? null, linkedin ?? null, twitter ?? null, website ?? null, req.user.id]
    );
    await conn.commit();
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
  if (oldEmail && changedEmail) {
    // Notify the OLD address that the email changed (best-effort, non-blocking).
    try {
      await sendEmailChanged({ to: oldEmail, newEmail: changedEmail });
    } catch (e) {
      console.error('[mail] email-changed send failed:', e.message);
    }
  }
  res.json(await loadProfile(req.user.id));
});

router.put('/me/skills', authRequired, async (req, res) => {
  const items = Array.isArray(req.body) ? req.body : [];
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    await conn.query('DELETE FROM user_skills WHERE user_id = ?', [req.user.id]);
    for (const it of items) {
      const skillId = Number(it.skill_id);
      const level = Math.max(1, Math.min(5, Number(it.level) || 3));
      if (!skillId) continue;
      await conn.query(
        'INSERT IGNORE INTO user_skills (user_id, skill_id, level) VALUES (?, ?, ?)',
        [req.user.id, skillId, level]
      );
    }
    await conn.commit();
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
  res.json(await loadProfile(req.user.id));
});

router.put('/me/interests', authRequired, async (req, res) => {
  const ids = Array.isArray(req.body) ? req.body.map(Number).filter(Boolean) : [];
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    await conn.query('DELETE FROM user_interests WHERE user_id = ?', [req.user.id]);
    for (const id of ids) {
      await conn.query(
        'INSERT IGNORE INTO user_interests (user_id, interest_id) VALUES (?, ?)',
        [req.user.id, id]
      );
    }
    await conn.commit();
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
  res.json(await loadProfile(req.user.id));
});

router.put('/me/password', authRequired, async (req, res) => {
  const current = req.body?.current_password ?? '';
  const next = req.body?.new_password ?? '';
  if (next.length < 8) return res.status(400).json({ error: 'new password must be at least 8 characters' });
  const [rows] = await pool.query('SELECT password_hash, email FROM users WHERE id = ?', [req.user.id]);
  if (!rows.length) return res.status(404).json({ error: 'user not found' });
  if (!(await verify(current, rows[0].password_hash))) {
    return res.status(401).json({ error: 'current password is incorrect' });
  }
  await pool.query('UPDATE users SET password_hash = ? WHERE id = ?', [await hash(next), req.user.id]);
  // Security confirmation email (best-effort, non-blocking).
  try {
    await sendPasswordChanged({ to: rows[0].email });
  } catch (e) {
    console.error('[mail] password-changed send failed:', e.message);
  }
  res.json({ ok: true });
});

router.delete('/me', authRequired, async (req, res) => {
  await pool.query('DELETE FROM users WHERE id = ?', [req.user.id]);
  res.json({ deleted: true });
});

router.get('/me/settings', authRequired, async (req, res) => {
  const [rows] = await pool.query(
    'SELECT setting_key, setting_value FROM user_settings WHERE user_id = ?',
    [req.user.id]
  );
  const out = {};
  for (const r of rows) out[r.setting_key] = r.setting_value;
  res.json(out);
});

router.put('/me/settings', authRequired, async (req, res) => {
  const body = (req.body && typeof req.body === 'object' && !Array.isArray(req.body)) ? req.body : {};
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    for (const [k, v] of Object.entries(body)) {
      await conn.query(
        `INSERT INTO user_settings (user_id, setting_key, setting_value) VALUES (?, ?, ?)
           ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)`,
        [req.user.id, String(k).slice(0, 60), String(v).slice(0, 255)]
      );
    }
    await conn.commit();
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
  const [rows] = await pool.query(
    'SELECT setting_key, setting_value FROM user_settings WHERE user_id = ?',
    [req.user.id]
  );
  const out = {};
  for (const r of rows) out[r.setting_key] = r.setting_value;
  res.json(out);
});

router.get('/:id', authRequired, async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: 'invalid id' });
  const profile = await loadProfile(id);
  if (!profile) return res.status(404).json({ error: 'user not found' });
  if (id !== req.user.id) {
    const s = await getSettings(id);
    if (!enabled(s, 'showEmail')) profile.email = null;
    if (!enabled(s, 'showPhone')) profile.phone = null;
  }
  res.json(profile);
});

module.exports = router;
