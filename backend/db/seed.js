require('dotenv').config();
const bcrypt = require('bcryptjs');
const pool = require('../src/config/db');

const SKILLS = [
  ['JavaScript', 'Frontend'], ['TypeScript', 'Frontend'], ['React', 'Frontend'],
  ['Flutter', 'Mobile'], ['Swift', 'Mobile'], ['Kotlin', 'Mobile'],
  ['Node.js', 'Backend'], ['Express', 'Backend'], ['Python', 'Backend'],
  ['SQL', 'Database'], ['MariaDB', 'Database'], ['MongoDB', 'Database'],
  ['UI/UX Design', 'Design'], ['Figma', 'Design'],
  ['Machine Learning', 'AI'], ['NLP', 'AI'],
  ['Project Management', 'Soft Skills'], ['Agile', 'Soft Skills']
];

const INTERESTS = [
  'Web Development', 'Mobile Apps', 'AI', 'Game Dev',
  'Open Source', 'Startups', 'Cybersecurity', 'Design',
  'EdTech', 'Social Impact'
];

const USERS = [
  { email: 'alice@school.fr', full_name: 'Alice Martin',
    bio: 'Frontend dev passionate about UX',
    skills: [['JavaScript', 5], ['React', 5], ['UI/UX Design', 4], ['Figma', 4]],
    interests: ['Web Development', 'Design', 'Startups'] },
  { email: 'bob@school.fr', full_name: 'Bob Dupont',
    bio: 'Backend / data nerd',
    skills: [['Node.js', 5], ['Express', 5], ['SQL', 5], ['MariaDB', 4], ['Python', 3]],
    interests: ['Web Development', 'Open Source'] },
  { email: 'chloe@school.fr', full_name: 'Chloé Lefèvre',
    bio: 'Designer learning Flutter',
    skills: [['Figma', 5], ['UI/UX Design', 5], ['Flutter', 3]],
    interests: ['Mobile Apps', 'Design', 'EdTech'] },
  { email: 'diane@school.fr', full_name: 'Diane Bernard',
    bio: 'ML student',
    skills: [['Python', 5], ['Machine Learning', 4], ['NLP', 3], ['SQL', 3]],
    interests: ['AI', 'Social Impact'] },
  { email: 'erwan@school.fr', full_name: 'Erwan Tran',
    bio: 'Mobile dev (Flutter & Kotlin)',
    skills: [['Flutter', 5], ['Kotlin', 4], ['JavaScript', 3]],
    interests: ['Mobile Apps', 'Startups'] },
  { email: 'farah@school.fr', full_name: 'Farah Idrissi',
    bio: 'Generalist + project manager',
    skills: [['Project Management', 5], ['Agile', 4], ['JavaScript', 3]],
    interests: ['Startups', 'Open Source', 'EdTech'] }
];

const PROJECTS = [
  { owner: 'alice@school.fr', title: 'StudyMate – peer revision sessions',
    description: 'A mobile app to organize study groups by course and level.',
    required: [['Flutter', 5], ['Node.js', 4], ['UI/UX Design', 3]],
    interests: ['Mobile Apps', 'EdTech'] },
  { owner: 'bob@school.fr', title: 'OpenLab – student project marketplace',
    description: 'A web platform for students to publish open-source side projects.',
    required: [['React', 4], ['Node.js', 5], ['SQL', 4]],
    interests: ['Web Development', 'Open Source'] },
  { owner: 'diane@school.fr', title: 'CampusBot – NLP assistant for student questions',
    description: 'An NLP chatbot that answers questions about school admin.',
    required: [['Python', 5], ['NLP', 4], ['Machine Learning', 4]],
    interests: ['AI', 'EdTech'] }
];

async function main() {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    for (const [name, cat] of SKILLS) {
      await conn.query('INSERT IGNORE INTO skills (name, category) VALUES (?, ?)', [name, cat]);
    }
    const [skillRows] = await conn.query('SELECT id, name FROM skills');
    const skillId = new Map(skillRows.map(r => [r.name, r.id]));

    for (const name of INTERESTS) {
      await conn.query('INSERT IGNORE INTO interests (name) VALUES (?)', [name]);
    }
    const [intRows] = await conn.query('SELECT id, name FROM interests');
    const interestId = new Map(intRows.map(r => [r.name, r.id]));

    const passwordHash = await bcrypt.hash('password', 10);
    for (const u of USERS) {
      await conn.query(
        `INSERT INTO users (email, password_hash, full_name, bio)
         VALUES (?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE full_name = VALUES(full_name), bio = VALUES(bio)`,
        [u.email, passwordHash, u.full_name, u.bio]
      );
    }
    const [userRows] = await conn.query('SELECT id, email FROM users');
    const userId = new Map(userRows.map(r => [r.email, r.id]));

    for (const u of USERS) {
      const uid = userId.get(u.email);
      await conn.query('DELETE FROM user_skills WHERE user_id = ?', [uid]);
      for (const [name, level] of u.skills) {
        await conn.query(
          'INSERT INTO user_skills (user_id, skill_id, level) VALUES (?, ?, ?)',
          [uid, skillId.get(name), level]
        );
      }
      await conn.query('DELETE FROM user_interests WHERE user_id = ?', [uid]);
      for (const name of u.interests) {
        await conn.query(
          'INSERT INTO user_interests (user_id, interest_id) VALUES (?, ?)',
          [uid, interestId.get(name)]
        );
      }
    }

    for (const p of PROJECTS) {
      const owner = userId.get(p.owner);
      const [existing] = await conn.query(
        'SELECT id FROM projects WHERE title = ? AND owner_id = ?',
        [p.title, owner]
      );
      if (existing.length) continue;

      const [r] = await conn.query(
        'INSERT INTO projects (owner_id, title, description) VALUES (?, ?, ?)',
        [owner, p.title, p.description]
      );
      const pid = r.insertId;
      await conn.query(
        'INSERT INTO project_members (project_id, user_id, role) VALUES (?, ?, ?)',
        [pid, owner, 'owner']
      );
      for (const [name, weight] of p.required) {
        await conn.query(
          'INSERT INTO project_required_skills (project_id, skill_id, weight) VALUES (?, ?, ?)',
          [pid, skillId.get(name), weight]
        );
      }
      for (const name of p.interests) {
        await conn.query(
          'INSERT INTO project_interests (project_id, interest_id) VALUES (?, ?)',
          [pid, interestId.get(name)]
        );
      }
    }

    await conn.commit();
    console.log('Seed OK. Demo password for all users: "password"');
  } catch (e) {
    await conn.rollback();
    console.error('Seed failed:', e);
    process.exit(1);
  } finally {
    conn.release();
    await pool.end();
  }
}

main();
