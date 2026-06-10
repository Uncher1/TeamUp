// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const pool = require('../config/db');

// score = wSkill * skill_match + (1 - wSkill) * interest_match    (∈ [0, 1])
// wSkill is per-project (projects.skill_weight), chosen by the team chief at
// creation. Defaults to 0.70 (the legacy fixed 70% skills / 30% interests).
const DEFAULT_SKILL_WEIGHT = 0.7;

const clampWeight = (w) => {
  const n = Number(w);
  return isNaN(n) ? DEFAULT_SKILL_WEIGHT : Math.max(0, Math.min(1, n));
};

const round = (x) => Number(x.toFixed(3));

function jaccard(a, b) {
  if (!a.size && !b.size) return 0;
  let inter = 0;
  for (const x of a) if (b.has(x)) inter++;
  const union = a.size + b.size - inter;
  return union ? inter / union : 0;
}

async function rankUsersForProject(projectId, limit = 10) {
  const [projectRows] = await pool.query(
    'SELECT id, owner_id, skill_weight FROM projects WHERE id = ?',
    [projectId]
  );
  if (!projectRows.length) return [];
  const project = projectRows[0];
  const wSkill = clampWeight(project.skill_weight);
  const wInterest = 1 - wSkill;

  const [reqSkills] = await pool.query(
    'SELECT skill_id, weight FROM project_required_skills WHERE project_id = ?',
    [projectId]
  );
  if (!reqSkills.length) return [];

  const skillWeight = new Map(reqSkills.map(r => [r.skill_id, r.weight]));
  const maxSkillScore = reqSkills.reduce((a, r) => a + r.weight * 5, 0);
  const requiredSkillIds = [...skillWeight.keys()];

  const [projectInts] = await pool.query(
    'SELECT interest_id FROM project_interests WHERE project_id = ?',
    [projectId]
  );
  const projectInterestSet = new Set(projectInts.map(r => r.interest_id));

  const [members] = await pool.query(
    'SELECT user_id FROM project_members WHERE project_id = ?',
    [projectId]
  );
  const excluded = new Set(members.map(m => m.user_id));
  excluded.add(project.owner_id);

  // Pre-filter: only users who declare at least one of the required skills.
  // Avoids loading the full user_skills table into memory.
  const [candidates] = await pool.query(
    `SELECT DISTINCT u.id, u.full_name, u.role, u.bio, u.avatar_url, u.presence_status
       FROM users u
       JOIN user_skills us ON us.user_id = u.id
      WHERE us.skill_id IN (?)
        AND u.id NOT IN (?)
        AND u.id NOT IN (
          SELECT user_id FROM user_settings
           WHERE setting_key = 'appearInSearch' AND setting_value = 'false'
        )`,
    [requiredSkillIds, [...excluded, 0]]
  );
  if (!candidates.length) return [];

  const candidateIds = candidates.map(c => c.id);

  const [candidateSkills] = await pool.query(
    'SELECT user_id, skill_id, level FROM user_skills WHERE user_id IN (?)',
    [candidateIds]
  );
  const userSkills = new Map();
  for (const r of candidateSkills) {
    if (!userSkills.has(r.user_id)) userSkills.set(r.user_id, []);
    userSkills.get(r.user_id).push(r);
  }

  const [candidateInterests] = await pool.query(
    'SELECT user_id, interest_id FROM user_interests WHERE user_id IN (?)',
    [candidateIds]
  );
  const userInterests = new Map();
  for (const r of candidateInterests) {
    if (!userInterests.has(r.user_id)) userInterests.set(r.user_id, new Set());
    userInterests.get(r.user_id).add(r.interest_id);
  }

  return candidates
    .map(u => {
      const skills = userSkills.get(u.id) || [];
      let raw = 0;
      const matched = [];
      for (const s of skills) {
        const w = skillWeight.get(s.skill_id);
        if (w) {
          raw += w * s.level;
          matched.push(s.skill_id);
        }
      }
      const skill_match = raw / maxSkillScore;
      const interest_match = jaccard(
        userInterests.get(u.id) || new Set(),
        projectInterestSet
      );
      const score = wSkill * skill_match + wInterest * interest_match;
      return {
        user_id: u.id,
        full_name: u.full_name,
        role: u.role,
        bio: u.bio,
        avatar_url: u.avatar_url,
        presence_status: u.presence_status,
        skill_match: round(skill_match),
        interest_match: round(interest_match),
        score: round(score),
        matched_skill_ids: matched
      };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);
}

async function rankProjectsForUser(userId, limit = 10) {
  const [userSkillsRows] = await pool.query(
    'SELECT skill_id, level FROM user_skills WHERE user_id = ?',
    [userId]
  );
  if (!userSkillsRows.length) return [];

  const userSkillMap = new Map(userSkillsRows.map(r => [r.skill_id, r.level]));
  const userSkillIds = [...userSkillMap.keys()];

  const [userIntRows] = await pool.query(
    'SELECT interest_id FROM user_interests WHERE user_id = ?',
    [userId]
  );
  const userInterestSet = new Set(userIntRows.map(r => r.interest_id));

  // Pre-filter: only open projects requiring at least one of the user's skills.
  const [projects] = await pool.query(
    `SELECT DISTINCT p.id, p.title, p.description, p.owner_id, p.skill_weight, u.full_name AS owner_name
       FROM projects p
       JOIN users u ON u.id = p.owner_id
       JOIN project_required_skills prs ON prs.project_id = p.id
      WHERE p.status = 'open'
        AND p.owner_id <> ?
        AND prs.skill_id IN (?)
        AND p.id NOT IN (SELECT project_id FROM project_members WHERE user_id = ?)`,
    [userId, userSkillIds, userId]
  );
  if (!projects.length) return [];

  const projectIds = projects.map(p => p.id);

  const [allReq] = await pool.query(
    'SELECT project_id, skill_id, weight FROM project_required_skills WHERE project_id IN (?)',
    [projectIds]
  );
  const reqByProject = new Map();
  for (const r of allReq) {
    if (!reqByProject.has(r.project_id)) reqByProject.set(r.project_id, []);
    reqByProject.get(r.project_id).push(r);
  }

  const [allProjInt] = await pool.query(
    'SELECT project_id, interest_id FROM project_interests WHERE project_id IN (?)',
    [projectIds]
  );
  const intByProject = new Map();
  for (const r of allProjInt) {
    if (!intByProject.has(r.project_id)) intByProject.set(r.project_id, new Set());
    intByProject.get(r.project_id).add(r.interest_id);
  }

  return projects
    .map(p => {
      const req = reqByProject.get(p.id) || [];
      const maxSkillScore = req.reduce((a, r) => a + r.weight * 5, 0) || 1;
      let raw = 0;
      for (const r of req) {
        const lvl = userSkillMap.get(r.skill_id);
        if (lvl) raw += r.weight * lvl;
      }
      const skill_match = raw / maxSkillScore;
      const interest_match = jaccard(
        userInterestSet,
        intByProject.get(p.id) || new Set()
      );
      const wSkill = clampWeight(p.skill_weight);
      const score = wSkill * skill_match + (1 - wSkill) * interest_match;
      return {
        project_id: p.id,
        title: p.title,
        description: p.description,
        owner_id: p.owner_id,
        owner_name: p.owner_name,
        skill_match: round(skill_match),
        interest_match: round(interest_match),
        score: round(score)
      };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);
}

module.exports = { rankUsersForProject, rankProjectsForUser };
