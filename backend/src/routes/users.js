// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const express = require('express');
const pool = require('../config/db');
const { authRequired } = require('../middleware/auth');
const { hash, verify } = require('../utils/password');
const { getSettings, enabled, getUserLanguage } = require('../services/settings');
const { relationship } = require('./social');
const { effectivePresence } = require('../services/presence');
const {
  sendEmailChangeRequest, sendPasswordChangeRequest,
  sendEmailChanged, sendPasswordChanged, sendDataExport,
} = require('../services/mailer');
const { generateCode } = require('../utils/code');
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const CHANGE_TTL_MS = 30 * 60 * 1000; // 30 minutes

const router = express.Router();

async function loadProfile(userId) {
  const [users] = await pool.query(
    `SELECT id, email, full_name, role, presence_status, bio, avatar_url, created_at, email_verified,
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
  // NOTE: e-mail is intentionally NOT editable here — it goes through the
  // confirm-by-code flow (POST /me/email/request + /me/change/confirm).
  const { full_name, bio, avatar_url,
          phone, school, department, study_year, location,
          github, linkedin, twitter, website, presence_status } = req.body || {};
  // Presence is a small whitelist; anything else is ignored (left unchanged).
  const presence = ['online', 'dnd', 'offline'].includes(presence_status) ? presence_status : null;
  await pool.query(
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
        website    = COALESCE(?, website),
        presence_status = COALESCE(?, presence_status)
      WHERE id = ?`,
    [full_name ?? null, bio ?? null, avatar_url ?? null,
     phone ?? null, school ?? null, department ?? null, study_year ?? null, location ?? null,
     github ?? null, linkedin ?? null, twitter ?? null, website ?? null, presence, req.user.id]
  );
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

// Step 1 (password): verify current + new, stash a PENDING password and e-mail
// a confirmation code. The password is NOT changed until the code is confirmed.
router.put('/me/password', authRequired, async (req, res) => {
  const current = req.body?.current_password ?? '';
  const next = req.body?.new_password ?? '';
  if (next.length < 8) return res.status(400).json({ error: 'new password must be at least 8 characters' });
  const [rows] = await pool.query('SELECT password_hash, email, full_name FROM users WHERE id = ?', [req.user.id]);
  if (!rows.length) return res.status(404).json({ error: 'user not found' });
  if (!(await verify(current, rows[0].password_hash))) {
    return res.status(401).json({ error: 'current password is incorrect' });
  }
  const code = generateCode();
  const expires = new Date(Date.now() + CHANGE_TTL_MS);
  await pool.query(
    `UPDATE users SET pending_change_type = 'password', pending_password_hash = ?,
        pending_email = NULL, pending_change_code = ?, pending_change_expires = ?
       WHERE id = ?`,
    [await hash(next), code, expires, req.user.id]
  );
  const lang = await getUserLanguage(req.user.id);
  sendPasswordChangeRequest({ to: rows[0].email, code, name: rows[0].full_name, lang })
    .catch((e) => console.error('[mail] password-change-request failed:', e.message));
  res.json({ sent: true });
});

// Step 1 (email): validate the new address, stash it as PENDING and e-mail a
// confirmation code to the user's CURRENT (old) address. E-mail unchanged yet.
router.post('/me/email/request', authRequired, async (req, res) => {
  const email = String(req.body?.email ?? '').trim().toLowerCase();
  if (!EMAIL_RE.test(email)) return res.status(400).json({ error: 'invalid email format' });
  const [rows] = await pool.query('SELECT email, full_name FROM users WHERE id = ?', [req.user.id]);
  if (!rows.length) return res.status(404).json({ error: 'user not found' });
  if (rows[0].email === email) return res.status(400).json({ error: 'this is already your address' });
  const [dup] = await pool.query('SELECT id FROM users WHERE email = ? AND id != ?', [email, req.user.id]);
  if (dup.length) return res.status(409).json({ error: 'email already in use' });

  const code = generateCode();
  const expires = new Date(Date.now() + CHANGE_TTL_MS);
  await pool.query(
    `UPDATE users SET pending_change_type = 'email', pending_email = ?,
        pending_password_hash = NULL, pending_change_code = ?, pending_change_expires = ?
       WHERE id = ?`,
    [email, code, expires, req.user.id]
  );
  // Code goes to the CURRENT address so the old e-mail owner approves the switch.
  const lang = await getUserLanguage(req.user.id);
  sendEmailChangeRequest({ to: rows[0].email, newEmail: email, code, name: rows[0].full_name, lang })
    .catch((e) => console.error('[mail] email-change-request failed:', e.message));
  res.json({ sent: true });
});

// Step 2: confirm a pending e-mail/password change with the code, then apply it.
router.post('/me/change/confirm', authRequired, async (req, res) => {
  const code = String(req.body?.code ?? '').trim().toUpperCase();
  if (!code) return res.status(400).json({ error: 'code is required' });
  const [rows] = await pool.query(
    `SELECT email, pending_change_type, pending_email, pending_password_hash,
            pending_change_code, pending_change_expires
       FROM users WHERE id = ?`,
    [req.user.id]
  );
  const u = rows[0];
  if (!u) return res.status(404).json({ error: 'user not found' });
  if (!u.pending_change_type || !u.pending_change_code) {
    return res.status(400).json({ error: 'aucune demande en attente' });
  }
  if (u.pending_change_code !== code) return res.status(400).json({ error: 'code incorrect' });
  if (u.pending_change_expires && new Date(u.pending_change_expires).getTime() < Date.now()) {
    return res.status(400).json({ error: 'code expiré, renvoie un nouveau code' });
  }

  const clear = `pending_change_type = NULL, pending_email = NULL,
                 pending_password_hash = NULL, pending_change_code = NULL,
                 pending_change_expires = NULL`;

  if (u.pending_change_type === 'email') {
    // Re-check uniqueness at apply time (another account may have taken it).
    const [dup] = await pool.query('SELECT id FROM users WHERE email = ? AND id != ?', [u.pending_email, req.user.id]);
    if (dup.length) {
      await pool.query(`UPDATE users SET ${clear} WHERE id = ?`, [req.user.id]);
      return res.status(409).json({ error: 'email already in use' });
    }
    await pool.query(`UPDATE users SET email = ?, ${clear} WHERE id = ?`, [u.pending_email, req.user.id]);
    const lang = await getUserLanguage(req.user.id);
    sendEmailChanged({ to: u.email, newEmail: u.pending_email, lang })
      .catch((e) => console.error('[mail] email-changed failed:', e.message));
  } else if (u.pending_change_type === 'password') {
    await pool.query(`UPDATE users SET password_hash = ?, ${clear} WHERE id = ?`, [u.pending_password_hash, req.user.id]);
    const lang = await getUserLanguage(req.user.id);
    sendPasswordChanged({ to: u.email, lang })
      .catch((e) => console.error('[mail] password-changed failed:', e.message));
  }
  res.json({ confirmed: true, type: u.pending_change_type, user: await loadProfile(req.user.id) });
});

// Re-issues a fresh code for the pending change.
router.post('/me/change/resend', authRequired, async (req, res) => {
  const [rows] = await pool.query(
    `SELECT email, full_name, pending_change_type, pending_email
       FROM users WHERE id = ?`,
    [req.user.id]
  );
  const u = rows[0];
  if (!u || !u.pending_change_type) return res.status(400).json({ error: 'aucune demande en attente' });
  const code = generateCode();
  const expires = new Date(Date.now() + CHANGE_TTL_MS);
  await pool.query(
    'UPDATE users SET pending_change_code = ?, pending_change_expires = ? WHERE id = ?',
    [code, expires, req.user.id]
  );
  const lang = await getUserLanguage(req.user.id);
  if (u.pending_change_type === 'email') {
    sendEmailChangeRequest({ to: u.email, newEmail: u.pending_email, code, name: u.full_name, lang })
      .catch((e) => console.error('[mail] resend email-change failed:', e.message));
  } else {
    sendPasswordChangeRequest({ to: u.email, code, name: u.full_name, lang })
      .catch((e) => console.error('[mail] resend password-change failed:', e.message));
  }
  res.json({ sent: true });
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

// Builds the full GDPR export payload (+ section counts for the email summary).
async function buildExport(uid) {
  const profile = await loadProfile(uid);
  const [projects] = await pool.query(
    'SELECT id, title, description, category, status, created_at FROM projects WHERE owner_id = ?', [uid]);
  const [memberships] = await pool.query(
    'SELECT project_id, role, joined_at FROM project_members WHERE user_id = ?', [uid]);
  const [applications] = await pool.query(
    'SELECT id, project_id, message, status, created_at FROM project_applications WHERE user_id = ?', [uid]);
  const [posts] = await pool.query(
    'SELECT id, type, content, created_at FROM posts WHERE author_id = ?', [uid]);
  const [comments] = await pool.query(
    'SELECT id, post_id, content, created_at FROM post_comments WHERE author_id = ?', [uid]);
  // Attachment binaries are omitted to keep the export light (metadata only).
  const [messages] = await pool.query(
    'SELECT id, conversation_id, content, attachment_type, attachment_name, created_at FROM messages WHERE sender_id = ?', [uid]);
  const [settings] = await pool.query(
    'SELECT setting_key, setting_value FROM user_settings WHERE user_id = ?', [uid]);
  const [friends] = await pool.query(
    `SELECT u.id, u.full_name
       FROM friendships f
       JOIN users u ON u.id = IF(f.requester_id = ?, f.addressee_id, f.requester_id)
      WHERE f.status = 'accepted' AND (f.requester_id = ? OR f.addressee_id = ?)`,
    [uid, uid, uid]);
  const [blocked] = await pool.query(
    'SELECT blocked_id FROM blocks WHERE blocker_id = ?', [uid]);

  const data = {
    export_info: {
      app: 'TeamUp',
      generated_at: new Date().toISOString(),
      description: 'A copy of all personal data associated with your TeamUp account.',
    },
    profile,
    projects,
    memberships,
    applications,
    posts,
    comments,
    messages,
    friends,
    blocked_users: blocked.map((b) => b.blocked_id),
    settings: Object.fromEntries(settings.map((s) => [s.setting_key, s.setting_value])),
  };
  const counts = {
    projects: projects.length,
    memberships: memberships.length,
    applications: applications.length,
    posts: posts.length,
    comments: comments.length,
    messages: messages.length,
    friends: friends.length,
  };
  return { data, counts };
}

// GDPR data portability: download everything we hold about the user as JSON.
router.get('/me/export', authRequired, async (req, res) => {
  const { data } = await buildExport(req.user.id);
  res.setHeader('Content-Disposition', 'attachment; filename="teamup-my-data.json"');
  res.json(data);
});

// GDPR data portability (preferred): e-mail the export to the user's address.
router.post('/me/export/email', authRequired, async (req, res) => {
  const { data, counts } = await buildExport(req.user.id);
  const [u] = await pool.query('SELECT email, full_name FROM users WHERE id = ?', [req.user.id]);
  if (!u.length) return res.status(404).json({ error: 'user not found' });
  const lang = await getUserLanguage(req.user.id);
  try {
    await sendDataExport({
      to: u[0].email,
      name: u[0].full_name,
      json: JSON.stringify(data, null, 2),
      counts,
      lang,
    });
  } catch (e) {
    console.error('[mail] data-export failed:', e.message);
    return res.status(502).json({ error: 'could not send the export email' });
  }
  res.json({ sent: true, to: u[0].email });
});

router.get('/:id', authRequired, async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: 'invalid id' });
  const profile = await loadProfile(id);
  if (!profile) return res.status(404).json({ error: 'user not found' });
  if (id !== req.user.id) {
    const rel = await relationship(req.user.id, id);
    const s = await getSettings(id);
    // Respect the target's presence visibility (WhatsApp-style).
    const visibleStatus = await effectivePresence(req.user.id, id, profile.presence_status);
    // Private profile: only expose a minimal public identity to others, but
    // still include the viewer's relationship so they can act on the profile.
    if (!enabled(s, 'profilePublic')) {
      return res.json({
        id: profile.id,
        full_name: profile.full_name,
        avatar_url: profile.avatar_url,
        role: profile.role,
        presence_status: visibleStatus,
        is_private: true,
        ...rel,
      });
    }
    if (!enabled(s, 'showEmail')) profile.email = null;
    if (!enabled(s, 'showPhone')) profile.phone = null;
    profile.presence_status = visibleStatus;
    return res.json({ ...profile, ...rel });
  }
  res.json(profile);
});

module.exports = router;
