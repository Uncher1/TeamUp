// Expands + categorizes the skills and interests catalogs to cover ALL fields
// of study (not just software). Idempotent: existing rows get their category
// refreshed, new ones are inserted. Safe to re-run; does NOT touch users/projects.
require('dotenv').config();
const pool = require('../src/config/db');

// [name, category] — names are UNIQUE across the table.
const SKILLS = [
  // Programming
  ['Python', 'Programming'], ['JavaScript', 'Programming'], ['TypeScript', 'Programming'],
  ['Java', 'Programming'], ['C', 'Programming'], ['C++', 'Programming'], ['C#', 'Programming'],
  ['Go', 'Programming'], ['Rust', 'Programming'], ['PHP', 'Programming'], ['Ruby', 'Programming'],
  ['Swift', 'Programming'], ['Kotlin', 'Programming'], ['Dart', 'Programming'], ['R', 'Programming'],
  ['MATLAB', 'Programming'], ['SQL', 'Programming'],
  // Web & Mobile
  ['HTML', 'Web & Mobile'], ['CSS', 'Web & Mobile'], ['React', 'Web & Mobile'], ['Vue.js', 'Web & Mobile'],
  ['Angular', 'Web & Mobile'], ['Node.js', 'Web & Mobile'], ['Express', 'Web & Mobile'],
  ['Django', 'Web & Mobile'], ['Flask', 'Web & Mobile'], ['Spring', 'Web & Mobile'], ['Laravel', 'Web & Mobile'],
  ['Flutter', 'Web & Mobile'], ['React Native', 'Web & Mobile'], ['REST APIs', 'Web & Mobile'], ['GraphQL', 'Web & Mobile'],
  // Data & AI
  ['Machine Learning', 'Data & AI'], ['Deep Learning', 'Data & AI'], ['NLP', 'Data & AI'],
  ['Computer Vision', 'Data & AI'], ['Data Analysis', 'Data & AI'], ['Data Visualization', 'Data & AI'],
  ['Pandas', 'Data & AI'], ['NumPy', 'Data & AI'], ['TensorFlow', 'Data & AI'], ['PyTorch', 'Data & AI'],
  ['Big Data', 'Data & AI'], ['Power BI', 'Data & AI'], ['Tableau', 'Data & AI'],
  // Databases
  ['MySQL', 'Databases'], ['PostgreSQL', 'Databases'], ['MongoDB', 'Databases'], ['Redis', 'Databases'], ['Firebase', 'Databases'],
  // Cloud & DevOps
  ['Docker', 'Cloud & DevOps'], ['Kubernetes', 'Cloud & DevOps'], ['AWS', 'Cloud & DevOps'], ['Azure', 'Cloud & DevOps'],
  ['Google Cloud', 'Cloud & DevOps'], ['CI/CD', 'Cloud & DevOps'], ['Linux', 'Cloud & DevOps'], ['Git', 'Cloud & DevOps'],
  // Cybersecurity
  ['Network Security', 'Cybersecurity'], ['Cryptography', 'Cybersecurity'], ['Penetration Testing', 'Cybersecurity'],
  ['Ethical Hacking', 'Cybersecurity'], ['Digital Forensics', 'Cybersecurity'],
  // Design & UX
  ['UI/UX Design', 'Design & UX'], ['Figma', 'Design & UX'], ['Photoshop', 'Design & UX'], ['Illustrator', 'Design & UX'],
  ['Prototyping', 'Design & UX'], ['Graphic Design', 'Design & UX'], ['Motion Design', 'Design & UX'],
  ['3D Modeling', 'Design & UX'], ['Blender', 'Design & UX'],
  // Mechanical Engineering
  ['CAD', 'Mechanical Engineering'], ['SolidWorks', 'Mechanical Engineering'], ['CATIA', 'Mechanical Engineering'],
  ['Thermodynamics', 'Mechanical Engineering'], ['Fluid Mechanics', 'Mechanical Engineering'],
  ['Materials Science', 'Mechanical Engineering'], ['Manufacturing', 'Mechanical Engineering'], ['Finite Element Analysis', 'Mechanical Engineering'],
  // Electrical & Electronics
  ['Circuit Design', 'Electrical & Electronics'], ['Embedded Systems', 'Electrical & Electronics'], ['Arduino', 'Electrical & Electronics'],
  ['Raspberry Pi', 'Electrical & Electronics'], ['Signal Processing', 'Electrical & Electronics'], ['Power Systems', 'Electrical & Electronics'],
  ['PCB Design', 'Electrical & Electronics'], ['Robotics', 'Electrical & Electronics'], ['Automation', 'Electrical & Electronics'], ['PLC Programming', 'Electrical & Electronics'],
  // Civil Engineering
  ['Structural Analysis', 'Civil Engineering'], ['AutoCAD', 'Civil Engineering'], ['Construction Management', 'Civil Engineering'],
  ['Surveying', 'Civil Engineering'], ['Hydraulics', 'Civil Engineering'], ['BIM', 'Civil Engineering'],
  // Industrial & Process
  ['Lean Manufacturing', 'Industrial & Process'], ['Six Sigma', 'Industrial & Process'], ['Supply Chain', 'Industrial & Process'],
  ['Quality Management', 'Industrial & Process'], ['Operations Research', 'Industrial & Process'], ['Logistics', 'Industrial & Process'],
  // Mathematics
  ['Calculus', 'Mathematics'], ['Linear Algebra', 'Mathematics'], ['Probability', 'Mathematics'], ['Statistics', 'Mathematics'],
  ['Discrete Mathematics', 'Mathematics'], ['Optimization', 'Mathematics'],
  // Physics
  ['Classical Mechanics', 'Physics'], ['Electromagnetism', 'Physics'], ['Quantum Physics', 'Physics'],
  ['Optics', 'Physics'], ['Astrophysics', 'Physics'],
  // Chemistry
  ['Organic Chemistry', 'Chemistry'], ['Analytical Chemistry', 'Chemistry'], ['Biochemistry', 'Chemistry'],
  ['Chemical Engineering', 'Chemistry'], ['Lab Techniques', 'Chemistry'],
  // Biology & Health
  ['Molecular Biology', 'Biology & Health'], ['Genetics', 'Biology & Health'], ['Microbiology', 'Biology & Health'],
  ['Anatomy', 'Biology & Health'], ['Physiology', 'Biology & Health'], ['Pharmacology', 'Biology & Health'],
  ['Clinical Research', 'Biology & Health'], ['Nursing', 'Biology & Health'], ['Public Health', 'Biology & Health'],
  ['Nutrition', 'Biology & Health'], ['First Aid', 'Biology & Health'],
  // Business & Management
  ['Project Management', 'Business & Management'], ['Agile', 'Business & Management'], ['Scrum', 'Business & Management'],
  ['Business Strategy', 'Business & Management'], ['Entrepreneurship', 'Business & Management'], ['Business Analysis', 'Business & Management'],
  ['Consulting', 'Business & Management'], ['Human Resources', 'Business & Management'], ['Operations Management', 'Business & Management'],
  // Finance & Accounting
  ['Accounting', 'Finance & Accounting'], ['Financial Analysis', 'Finance & Accounting'], ['Excel', 'Finance & Accounting'],
  ['Auditing', 'Finance & Accounting'], ['Taxation', 'Finance & Accounting'], ['Investment', 'Finance & Accounting'],
  ['Financial Modeling', 'Finance & Accounting'], ['Risk Management', 'Finance & Accounting'],
  // Marketing & Communication
  ['Digital Marketing', 'Marketing & Communication'], ['SEO', 'Marketing & Communication'], ['Social Media Marketing', 'Marketing & Communication'],
  ['Content Creation', 'Marketing & Communication'], ['Branding', 'Marketing & Communication'], ['Market Research', 'Marketing & Communication'],
  ['Public Relations', 'Marketing & Communication'], ['Copywriting', 'Marketing & Communication'], ['Advertising', 'Marketing & Communication'],
  // Economics
  ['Microeconomics', 'Economics'], ['Macroeconomics', 'Economics'], ['Econometrics', 'Economics'], ['Game Theory', 'Economics'],
  // Law
  ['Contract Law', 'Law'], ['Corporate Law', 'Law'], ['Criminal Law', 'Law'], ['International Law', 'Law'],
  ['Intellectual Property', 'Law'], ['Legal Research', 'Law'],
  // Languages
  ['English', 'Languages'], ['French', 'Languages'], ['Spanish', 'Languages'], ['German', 'Languages'],
  ['Mandarin', 'Languages'], ['Arabic', 'Languages'], ['Italian', 'Languages'], ['Japanese', 'Languages'], ['Translation', 'Languages'],
  // Humanities
  ['History', 'Humanities'], ['Philosophy', 'Humanities'], ['Literature', 'Humanities'], ['Linguistics', 'Humanities'],
  ['Art History', 'Humanities'], ['Archaeology', 'Humanities'],
  // Social Sciences
  ['Psychology', 'Social Sciences'], ['Sociology', 'Social Sciences'], ['Political Science', 'Social Sciences'],
  ['Anthropology', 'Social Sciences'], ['Geography', 'Social Sciences'],
  // Education
  ['Teaching', 'Education'], ['Curriculum Design', 'Education'], ['E-learning', 'Education'], ['Pedagogy', 'Education'], ['Tutoring', 'Education'],
  // Arts
  ['Drawing', 'Arts'], ['Painting', 'Arts'], ['Photography', 'Arts'], ['Music Theory', 'Arts'], ['Music Production', 'Arts'],
  ['Singing', 'Arts'], ['Filmmaking', 'Arts'], ['Video Editing', 'Arts'], ['Animation', 'Arts'], ['Theatre', 'Arts'],
  // Media & Journalism
  ['Journalism', 'Media & Journalism'], ['Creative Writing', 'Media & Journalism'], ['Editing', 'Media & Journalism'],
  ['Podcasting', 'Media & Journalism'], ['Storytelling', 'Media & Journalism'],
  // Architecture & Urbanism
  ['Architectural Design', 'Architecture & Urbanism'], ['Urban Planning', 'Architecture & Urbanism'],
  ['Interior Design', 'Architecture & Urbanism'], ['Architectural Rendering', 'Architecture & Urbanism'],
  // Environment
  ['Environmental Science', 'Environment'], ['Sustainability', 'Environment'], ['Renewable Energy', 'Environment'],
  ['Ecology', 'Environment'], ['GIS', 'Environment'], ['Climate Science', 'Environment'],
  // Agriculture & Food
  ['Agronomy', 'Agriculture & Food'], ['Food Science', 'Agriculture & Food'], ['Veterinary Science', 'Agriculture & Food'], ['Horticulture', 'Agriculture & Food'],
  // Soft Skills
  ['Communication', 'Soft Skills'], ['Teamwork', 'Soft Skills'], ['Leadership', 'Soft Skills'], ['Problem Solving', 'Soft Skills'],
  ['Time Management', 'Soft Skills'], ['Critical Thinking', 'Soft Skills'], ['Public Speaking', 'Soft Skills'],
  ['Adaptability', 'Soft Skills'], ['Creativity', 'Soft Skills'], ['Negotiation', 'Soft Skills'],
];

// [name, category] — names are UNIQUE across the table.
const INTERESTS = [
  // Tech
  ['Web Development', 'Tech'], ['Mobile Apps', 'Tech'], ['Artificial Intelligence', 'Tech'], ['Cybersecurity', 'Tech'],
  ['Cloud Computing', 'Tech'], ['Blockchain', 'Tech'], ['IoT', 'Tech'], ['Data Science', 'Tech'],
  ['AR / VR', 'Tech'], ['Robotics', 'Tech'], ['Game Development', 'Tech'],
  // Science & Research
  ['Scientific Research', 'Science & Research'], ['Space & Astronomy', 'Science & Research'], ['Biology', 'Science & Research'],
  ['Physics', 'Science & Research'], ['Chemistry', 'Science & Research'], ['Mathematics', 'Science & Research'], ['Neuroscience', 'Science & Research'],
  // Engineering
  ['Mechanical Engineering', 'Engineering'], ['Electronics', 'Engineering'], ['Civil Engineering', 'Engineering'],
  ['Aerospace', 'Engineering'], ['Energy', 'Engineering'],
  // Health
  ['Medicine', 'Health'], ['Healthcare', 'Health'], ['Nutrition', 'Health'], ['Mental Health', 'Health'], ['Sports & Fitness', 'Health'],
  // Business
  ['Startups', 'Business'], ['Entrepreneurship', 'Business'], ['Marketing', 'Business'], ['Finance', 'Business'],
  ['Investing', 'Business'], ['Management', 'Business'], ['E-commerce', 'Business'],
  // Arts & Creative
  ['Design', 'Arts & Creative'], ['Music', 'Arts & Creative'], ['Photography', 'Arts & Creative'], ['Film & Video', 'Arts & Creative'],
  ['Writing', 'Arts & Creative'], ['Drawing', 'Arts & Creative'], ['Fashion', 'Arts & Creative'], ['Theatre & Dance', 'Arts & Creative'],
  // Society & Humanities
  ['Law', 'Society & Humanities'], ['Politics', 'Society & Humanities'], ['History', 'Society & Humanities'],
  ['Philosophy', 'Society & Humanities'], ['Psychology', 'Society & Humanities'], ['Languages', 'Society & Humanities'], ['Education', 'Society & Humanities'],
  // Environment
  ['Sustainability', 'Environment'], ['Climate Change', 'Environment'], ['Renewable Energy', 'Environment'],
  ['Ecology', 'Environment'], ['Agriculture', 'Environment'],
  // Media
  ['Journalism', 'Media'], ['Podcasting', 'Media'], ['Content Creation', 'Media'], ['Social Media', 'Media'],
  // Lifestyle
  ['Travel', 'Lifestyle'], ['Gaming', 'Lifestyle'], ['Volunteering', 'Lifestyle'], ['Social Impact', 'Lifestyle'],
  ['Open Source', 'Lifestyle'], ['Reading', 'Lifestyle'], ['Cooking', 'Lifestyle'],
];

(async () => {
  // Ensure interests.category exists (MariaDB-only IF NOT EXISTS, so swallow on MySQL 8).
  try {
    await pool.query("ALTER TABLE interests ADD COLUMN category VARCHAR(60)");
  } catch (_e) { /* column already present */ }
  console.log('ok: interests.category');

  // Clean reseed so the catalog has no leftover/orphan categories.
  // (Cascades to user_skills / user_interests / project_required_skills — fine
  // on a fresh DB with no real selections yet.)
  await pool.query('DELETE FROM skills');
  await pool.query('DELETE FROM interests');
  console.log('ok: cleared old catalog');

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
