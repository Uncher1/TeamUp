// Sets a user's moderation role. Usage:
//   node scripts/set-role.js <email> <user|moderator|admin>
// Used to seed the first admin, e.g. node scripts/set-role.js me@example.com admin
require('dotenv').config();
const pool = require('../src/config/db');

(async () => {
  const email = (process.argv[2] || '').trim().toLowerCase();
  const role = (process.argv[3] || '').trim();
  if (!email || !['user', 'moderator', 'admin'].includes(role)) {
    console.error('usage: node scripts/set-role.js <email> <user|moderator|admin>');
    process.exit(1);
  }
  const [r] = await pool.query('UPDATE users SET role = ? WHERE email = ?', [role, email]);
  console.log(r.affectedRows ? `OK: ${email} → ${role}` : `no user found for ${email}`);
  await pool.end();
})().catch((e) => {
  console.error('failed:', e.message);
  process.exit(1);
});
