// Expands + categorizes the skills and interests catalogs.
// - adds `category` to interests (idempotent)
// - upserts a large, categorized catalog (existing rows get their category set;
//   new ones are inserted). Safe to re-run; does NOT touch users/projects.
require('dotenv').config();
const pool = require('../src/config/db');

// [name, category]
const SKILLS = [
  // Frontend
  ['HTML', 'Frontend'], ['CSS', 'Frontend'], ['Sass', 'Frontend'],
  ['JavaScript', 'Frontend'], ['TypeScript', 'Frontend'], ['React', 'Frontend'],
  ['Vue.js', 'Frontend'], ['Angular', 'Frontend'], ['Next.js', 'Frontend'],
  ['Tailwind CSS', 'Frontend'],
  // Backend
  ['Node.js', 'Backend'], ['Express', 'Backend'], ['Python', 'Backend'],
  ['Django', 'Backend'], ['Flask', 'Backend'], ['Java', 'Backend'],
  ['Spring', 'Backend'], ['C#', 'Backend'], ['.NET', 'Backend'],
  ['Go', 'Backend'], ['Ruby on Rails', 'Backend'], ['PHP', 'Backend'],
  ['Laravel', 'Backend'], ['GraphQL', 'Backend'], ['REST APIs', 'Backend'],
  // Mobile
  ['Flutter', 'Mobile'], ['Dart', 'Mobile'], ['Swift', 'Mobile'],
  ['SwiftUI', 'Mobile'], ['Kotlin', 'Mobile'], ['Jetpack Compose', 'Mobile'],
  ['React Native', 'Mobile'],
  // Database
  ['SQL', 'Database'], ['PostgreSQL', 'Database'], ['MySQL', 'Database'],
  ['MariaDB', 'Database'], ['MongoDB', 'Database'], ['Redis', 'Database'],
  ['SQLite', 'Database'], ['Firebase', 'Database'],
  // DevOps
  ['Git', 'DevOps'], ['Docker', 'DevOps'], ['Kubernetes', 'DevOps'],
  ['CI/CD', 'DevOps'], ['AWS', 'DevOps'], ['Azure', 'DevOps'],
  ['Google Cloud', 'DevOps'], ['Linux', 'DevOps'],
  // AI & Data
  ['Machine Learning', 'AI & Data'], ['Deep Learning', 'AI & Data'],
  ['NLP', 'AI & Data'], ['Computer Vision', 'AI & Data'],
  ['Data Science', 'AI & Data'], ['Pandas', 'AI & Data'],
  ['TensorFlow', 'AI & Data'], ['PyTorch', 'AI & Data'],
  // Design
  ['UI/UX Design', 'Design'], ['Figma', 'Design'], ['Adobe XD', 'Design'],
  ['Photoshop', 'Design'], ['Illustrator', 'Design'], ['Prototyping', 'Design'],
  // Game Dev
  ['Unity', 'Game Dev'], ['Unreal Engine', 'Game Dev'], ['C++', 'Game Dev'],
  ['Godot', 'Game Dev'], ['Blender', 'Game Dev'],
  // Security
  ['Cybersecurity', 'Security'], ['Cryptography', 'Security'],
  ['Penetration Testing', 'Security'], ['Network Security', 'Security'],
  // Soft Skills
  ['Project Management', 'Soft Skills'], ['Agile', 'Soft Skills'],
  ['Scrum', 'Soft Skills'], ['Communication', 'Soft Skills'],
  ['Leadership', 'Soft Skills'], ['Teamwork', 'Soft Skills'],
  ['Public Speaking', 'Soft Skills'],
];

// [name, category]
const INTERESTS = [
  // Tech
  ['Web Development', 'Tech'], ['Mobile Apps', 'Tech'], ['AI', 'Tech'],
  ['Cybersecurity', 'Tech'], ['Cloud', 'Tech'], ['Blockchain', 'Tech'],
  ['IoT', 'Tech'], ['Data Science', 'Tech'], ['AR / VR', 'Tech'],
  ['DevOps', 'Tech'],
  // Creative
  ['Design', 'Creative'], ['Game Dev', 'Creative'], ['Music', 'Creative'],
  ['Photography', 'Creative'], ['Video', 'Creative'], ['Writing', 'Creative'],
  // Business
  ['Startups', 'Business'], ['Entrepreneurship', 'Business'],
  ['Marketing', 'Business'], ['Finance', 'Business'],
  ['Product Management', 'Business'],
  // Impact
  ['Social Impact', 'Impact'], ['EdTech', 'Impact'], ['HealthTech', 'Impact'],
  ['Sustainability', 'Impact'], ['Open Source', 'Impact'],
];

(async () => {
  await pool.query("ALTER TABLE interests ADD COLUMN IF NOT EXISTS category VARCHAR(60)");
  console.log('ok: interests.category');

  for (const [name, cat] of SKILLS) {
    await pool.query(
      `INSERT INTO skills (name, category) VALUES (?, ?)
         ON DUPLICATE KEY UPDATE category = VALUES(category)`,
      [name, cat]
    );
  }
  console.log(`ok: ${SKILLS.length} skills upserted`);

  for (const [name, cat] of INTERESTS) {
    await pool.query(
      `INSERT INTO interests (name, category) VALUES (?, ?)
         ON DUPLICATE KEY UPDATE category = VALUES(category)`,
      [name, cat]
    );
  }
  console.log(`ok: ${INTERESTS.length} interests upserted`);

  await pool.end();
  console.log('catalog seed done');
})().catch((e) => {
  console.error('failed:', e.message);
  process.exit(1);
});
