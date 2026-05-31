// Generates db/hosted-setup.sql: the CREATE TABLE statements (schema.sql minus
// the CREATE DATABASE / USE header) + the categorized skills/interests catalog,
// ready to import into an already-created database via phpMyAdmin (no demo data).
const fs = require('fs');
const path = require('path');

const SKILLS = [
  ['HTML', 'Frontend'], ['CSS', 'Frontend'], ['Sass', 'Frontend'],
  ['JavaScript', 'Frontend'], ['TypeScript', 'Frontend'], ['React', 'Frontend'],
  ['Vue.js', 'Frontend'], ['Angular', 'Frontend'], ['Next.js', 'Frontend'],
  ['Tailwind CSS', 'Frontend'],
  ['Node.js', 'Backend'], ['Express', 'Backend'], ['Python', 'Backend'],
  ['Django', 'Backend'], ['Flask', 'Backend'], ['Java', 'Backend'],
  ['Spring', 'Backend'], ['C#', 'Backend'], ['.NET', 'Backend'],
  ['Go', 'Backend'], ['Ruby on Rails', 'Backend'], ['PHP', 'Backend'],
  ['Laravel', 'Backend'], ['GraphQL', 'Backend'], ['REST APIs', 'Backend'],
  ['Flutter', 'Mobile'], ['Dart', 'Mobile'], ['Swift', 'Mobile'],
  ['SwiftUI', 'Mobile'], ['Kotlin', 'Mobile'], ['Jetpack Compose', 'Mobile'],
  ['React Native', 'Mobile'],
  ['SQL', 'Database'], ['PostgreSQL', 'Database'], ['MySQL', 'Database'],
  ['MariaDB', 'Database'], ['MongoDB', 'Database'], ['Redis', 'Database'],
  ['SQLite', 'Database'], ['Firebase', 'Database'],
  ['Git', 'DevOps'], ['Docker', 'DevOps'], ['Kubernetes', 'DevOps'],
  ['CI/CD', 'DevOps'], ['AWS', 'DevOps'], ['Azure', 'DevOps'],
  ['Google Cloud', 'DevOps'], ['Linux', 'DevOps'],
  ['Machine Learning', 'AI & Data'], ['Deep Learning', 'AI & Data'],
  ['NLP', 'AI & Data'], ['Computer Vision', 'AI & Data'],
  ['Data Science', 'AI & Data'], ['Pandas', 'AI & Data'],
  ['TensorFlow', 'AI & Data'], ['PyTorch', 'AI & Data'],
  ['UI/UX Design', 'Design'], ['Figma', 'Design'], ['Adobe XD', 'Design'],
  ['Photoshop', 'Design'], ['Illustrator', 'Design'], ['Prototyping', 'Design'],
  ['Unity', 'Game Dev'], ['Unreal Engine', 'Game Dev'], ['C++', 'Game Dev'],
  ['Godot', 'Game Dev'], ['Blender', 'Game Dev'],
  ['Cybersecurity', 'Security'], ['Cryptography', 'Security'],
  ['Penetration Testing', 'Security'], ['Network Security', 'Security'],
  ['Project Management', 'Soft Skills'], ['Agile', 'Soft Skills'],
  ['Scrum', 'Soft Skills'], ['Communication', 'Soft Skills'],
  ['Leadership', 'Soft Skills'], ['Teamwork', 'Soft Skills'],
  ['Public Speaking', 'Soft Skills'],
];

const INTERESTS = [
  ['Web Development', 'Tech'], ['Mobile Apps', 'Tech'], ['AI', 'Tech'],
  ['Cybersecurity', 'Tech'], ['Cloud', 'Tech'], ['Blockchain', 'Tech'],
  ['IoT', 'Tech'], ['Data Science', 'Tech'], ['AR / VR', 'Tech'],
  ['DevOps', 'Tech'],
  ['Design', 'Creative'], ['Game Dev', 'Creative'], ['Music', 'Creative'],
  ['Photography', 'Creative'], ['Video', 'Creative'], ['Writing', 'Creative'],
  ['Startups', 'Business'], ['Entrepreneurship', 'Business'],
  ['Marketing', 'Business'], ['Finance', 'Business'],
  ['Product Management', 'Business'],
  ['Social Impact', 'Impact'], ['EdTech', 'Impact'], ['HealthTech', 'Impact'],
  ['Sustainability', 'Impact'], ['Open Source', 'Impact'],
];

const schema = fs.readFileSync(path.join(__dirname, '..', 'db', 'schema.sql'), 'utf8')
  .replace(/CREATE DATABASE[\s\S]*?;/i, '')
  .replace(/USE\s+\w+\s*;/i, '')
  .trim();

const rows = (arr) => arr.map(([n, c]) => `  ('${n}', '${c}')`).join(',\n');

const out =
  `-- TeamUp hosted DB setup (import via phpMyAdmin into an existing database).\n` +
  `-- Tables + categorized skills/interests catalog. No demo data.\n\n` +
  schema + '\n\n' +
  `-- ---------------------------------------------------------------------------\n` +
  `-- Catalog: skills + interests\n` +
  `-- ---------------------------------------------------------------------------\n` +
  `INSERT INTO skills (name, category) VALUES\n${rows(SKILLS)};\n\n` +
  `INSERT INTO interests (name, category) VALUES\n${rows(INTERESTS)};\n`;

const target = path.join(__dirname, '..', 'db', 'hosted-setup.sql');
fs.writeFileSync(target, out);
console.log(`Wrote ${target}`);
console.log(`  ${SKILLS.length} skills, ${INTERESTS.length} interests`);
