// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const express = require('express');
const pool = require('../config/db');
const { authRequired } = require('../middleware/auth');
const { createNotification } = require('../services/notifications');

// True if the user may moderate others' content (moderator or admin).
async function isPrivileged(userId) {
  const [r] = await pool.query('SELECT role FROM users WHERE id = ?', [userId]);
  return ['moderator', 'admin'].includes(r[0]?.role);
}

const router = express.Router();

async function loadProject(id) {
  const [projects] = await pool.query(
    `SELECT p.id, p.title, p.description, p.category, p.team_size, p.timeline,
            p.status, p.created_at,
            u.id AS owner_id, u.full_name AS owner_name
       FROM projects p JOIN users u ON u.id = p.owner_id
      WHERE p.id = ?`,
    [id]
  );
  if (!projects.length) return null;
  const project = projects[0];
  const [skills] = await pool.query(
    `SELECT s.id, s.name, prs.weight
       FROM project_required_skills prs JOIN skills s ON s.id = prs.skill_id
      WHERE prs.project_id = ?`,
    [id]
  );
  const [interests] = await pool.query(
    `SELECT i.id, i.name
       FROM project_interests pi JOIN interests i ON i.id = pi.interest_id
      WHERE pi.project_id = ?`,
    [id]
  );
  const [members] = await pool.query(
    `SELECT u.id, u.full_name, u.avatar_url, u.presence_status, pm.role, pm.joined_at
       FROM project_members pm JOIN users u ON u.id = pm.user_id
      WHERE pm.project_id = ?`,
    [id]
  );
  return { ...project, required_skills: skills, interests, members };
}

router.get('/', authRequired, async (_req, res) => {
  const [rows] = await pool.query(
    `SELECT p.id, p.title, p.description, p.category, p.team_size, p.timeline,
            p.status, p.created_at,
            u.id AS owner_id, u.full_name AS owner_name
       FROM projects p JOIN users u ON u.id = p.owner_id
      WHERE p.status = 'open'
      ORDER BY p.created_at DESC LIMIT 100`
  );
  res.json(rows);
});

router.get('/mine', authRequired, async (req, res) => {
  const [rows] = await pool.query(
    `SELECT p.id, p.title, p.description, p.category, p.team_size, p.timeline,
            p.status, p.created_at,
            u.id AS owner_id, u.full_name AS owner_name, pm.role AS my_role
       FROM project_members pm
       JOIN projects p ON p.id = pm.project_id
       JOIN users u    ON u.id = p.owner_id
      WHERE pm.user_id = ?
      ORDER BY p.created_at DESC`,
    [req.user.id]
  );
  for (const p of rows) {
    const [members] = await pool.query(
      `SELECT u.id, u.full_name, u.avatar_url, pm.role
         FROM project_members pm JOIN users u ON u.id = pm.user_id
        WHERE pm.project_id = ?`,
      [p.id]
    );
    p.members = members;
  }
  res.json(rows);
});

router.post('/', authRequired, async (req, res) => {
  const { title, description, required_skills = [], interests = [],
          category = null, team_size = null, timeline = null } = req.body || {};
  if (!title || !description) {
    return res.status(400).json({ error: 'title and description are required' });
  }
  const cat = category ? String(category).slice(0, 40) : null;
  const size = team_size != null ? Math.max(1, Math.min(50, Number(team_size) || 0)) || null : null;
  const tl = timeline ? String(timeline).slice(0, 20) : null;
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [r] = await conn.query(
      'INSERT INTO projects (owner_id, title, description, category, team_size, timeline) VALUES (?, ?, ?, ?, ?, ?)',
      [req.user.id, title, description, cat, size, tl]
    );
    const id = r.insertId;
    await conn.query(
      'INSERT INTO project_members (project_id, user_id, role) VALUES (?, ?, ?)',
      [id, req.user.id, 'owner']
    );
    for (const s of required_skills) {
      const sid = Number(s.skill_id);
      const w = Math.max(1, Math.min(5, Number(s.weight) || 3));
      if (!sid) continue;
      await conn.query(
        'INSERT IGNORE INTO project_required_skills (project_id, skill_id, weight) VALUES (?, ?, ?)',
        [id, sid, w]
      );
    }
    for (const iid of interests.map(Number).filter(Boolean)) {
      await conn.query(
        'INSERT IGNORE INTO project_interests (project_id, interest_id) VALUES (?, ?)',
        [id, iid]
      );
    }
    await conn.commit();
    res.status(201).json(await loadProject(id));
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
});

router.get('/:id', authRequired, async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: 'invalid id' });
  const project = await loadProject(id);
  if (!project) return res.status(404).json({ error: 'project not found' });
  res.json(project);
});

router.post('/:id/apply', authRequired, async (req, res) => {
  const projectId = Number(req.params.id);
  const message = (req.body && req.body.message) || null;

  const [projects] = await pool.query(
    'SELECT id, owner_id, status FROM projects WHERE id = ?',
    [projectId]
  );
  const p = projects[0];
  if (!p) return res.status(404).json({ error: 'project not found' });
  if (p.status !== 'open') return res.status(400).json({ error: 'project is not open' });
  if (p.owner_id === req.user.id) return res.status(400).json({ error: 'owner cannot apply' });

  const [members] = await pool.query(
    'SELECT 1 AS x FROM project_members WHERE project_id = ? AND user_id = ?',
    [projectId, req.user.id]
  );
  if (members.length) return res.status(400).json({ error: 'already a member' });

  await pool.query(
    `INSERT INTO project_applications (project_id, user_id, message) VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE message = VALUES(message), status = 'pending'`,
    [projectId, req.user.id, message]
  );
  const [applicants] = await pool.query('SELECT full_name FROM users WHERE id = ?', [req.user.id]);
  const [projTitle] = await pool.query('SELECT title FROM projects WHERE id = ?', [projectId]);
  await createNotification(req.app.get('io'), {
    userId: p.owner_id,
    type: 'application',
    title: `${applicants[0].full_name} a postulé à ${projTitle[0].title}`,
    body: message || null,
    linkType: 'project',
    linkId: projectId,
  });
  res.status(201).json({ status: 'pending' });
});

router.get('/:id/applications', authRequired, async (req, res) => {
  const projectId = Number(req.params.id);
  if (!projectId) return res.status(400).json({ error: 'invalid id' });

  const [projects] = await pool.query('SELECT owner_id FROM projects WHERE id = ?', [projectId]);
  const project = projects[0];
  if (!project) return res.status(404).json({ error: 'project not found' });
  if (project.owner_id !== req.user.id) return res.status(403).json({ error: 'only owner can view applications' });

  const [rows] = await pool.query(
    `SELECT pa.id, pa.status, pa.message, pa.created_at,
            u.id AS user_id, u.full_name, u.email
       FROM project_applications pa JOIN users u ON u.id = pa.user_id
      WHERE pa.project_id = ?
      ORDER BY pa.created_at DESC`,
    [projectId]
  );
  res.json(rows);
});

router.post('/:id/applications/:aid', authRequired, async (req, res) => {
  const projectId = Number(req.params.id);
  const appId = Number(req.params.aid);
  const action = (req.body && req.body.action) || '';
  if (!['accept', 'reject'].includes(action)) {
    return res.status(400).json({ error: 'action must be "accept" or "reject"' });
  }

  const [projects] = await pool.query('SELECT owner_id FROM projects WHERE id = ?', [projectId]);
  const project = projects[0];
  if (!project) return res.status(404).json({ error: 'project not found' });
  if (project.owner_id !== req.user.id) return res.status(403).json({ error: 'only owner can decide' });

  const [apps] = await pool.query(
    'SELECT id, user_id, status FROM project_applications WHERE id = ? AND project_id = ?',
    [appId, projectId]
  );
  const app = apps[0];
  if (!app) return res.status(404).json({ error: 'application not found' });
  if (app.status !== 'pending') return res.status(400).json({ error: 'application already decided' });

  if (action === 'accept') {
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      await conn.query('UPDATE project_applications SET status = ? WHERE id = ?', ['accepted', appId]);
      await conn.query(
        'INSERT IGNORE INTO project_members (project_id, user_id, role) VALUES (?, ?, ?)',
        [projectId, app.user_id, 'member']
      );
      await conn.commit();
    } catch (e) { await conn.rollback(); throw e; } finally { conn.release(); }
  } else {
    await pool.query('UPDATE project_applications SET status = ? WHERE id = ?', ['rejected', appId]);
  }

  await createNotification(req.app.get('io'), {
    userId: app.user_id,
    type: action === 'accept' ? 'team_join' : 'project_update',
    title: action === 'accept' ? 'Ta candidature a été acceptée 🎉' : 'Ta candidature a été refusée',
    body: null,
    linkType: 'project',
    linkId: projectId,
  });
  res.json({ status: action === 'accept' ? 'accepted' : 'rejected' });
});

router.post('/:id/conversation', authRequired, async (req, res) => {
  const projectId = Number(req.params.id);

  const [members] = await pool.query(
    'SELECT 1 AS x FROM project_members WHERE project_id = ? AND user_id = ?',
    [projectId, req.user.id]
  );
  if (!members.length) return res.status(403).json({ error: 'not a project member' });

  const [existing] = await pool.query(
    "SELECT id FROM conversations WHERE type = 'project' AND project_id = ?",
    [projectId]
  );
  if (existing.length) {
    return res.json({ id: existing[0].id, type: 'project', project_id: projectId });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [r] = await conn.query(
      "INSERT INTO conversations (type, project_id) VALUES ('project', ?)",
      [projectId]
    );
    const id = r.insertId;
    const [pm] = await conn.query(
      'SELECT user_id FROM project_members WHERE project_id = ?',
      [projectId]
    );
    for (const m of pm) {
      await conn.query(
        'INSERT IGNORE INTO conversation_members (conversation_id, user_id) VALUES (?, ?)',
        [id, m.user_id]
      );
    }
    await conn.commit();
    res.status(201).json({ id, type: 'project', project_id: projectId });
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
});

// Delete a project — its owner, or a moderator/admin (content moderation).
router.delete('/:id', authRequired, async (req, res) => {
  const projectId = Number(req.params.id);
  if (!projectId) return res.status(400).json({ error: 'invalid id' });
  const [projects] = await pool.query('SELECT owner_id FROM projects WHERE id = ?', [projectId]);
  if (!projects.length) return res.status(404).json({ error: 'project not found' });
  if (projects[0].owner_id !== req.user.id && !(await isPrivileged(req.user.id))) {
    return res.status(403).json({ error: 'not allowed' });
  }
  await pool.query('DELETE FROM projects WHERE id = ?', [projectId]);
  res.json({ deleted: true });
});

module.exports = router;
