const pool = require('../config/db');

// Returns { key: 'true'|'false', ... } for the user (may be empty).
async function getSettings(userId) {
  const [rows] = await pool.query(
    'SELECT setting_key, setting_value FROM user_settings WHERE user_id = ?', [userId]);
  const out = {};
  for (const r of rows) out[r.setting_key] = r.setting_value;
  return out;
}

// true unless explicitly 'false'.
function enabled(settings, key) { return settings[key] !== 'false'; }

// The user's saved UI language ('en' | 'fr'); defaults to 'en'. Used to send
// e-mails in the recipient's language.
async function getUserLanguage(userId) {
  const [rows] = await pool.query(
    "SELECT setting_value FROM user_settings WHERE user_id = ? AND setting_key = 'language'",
    [userId]
  );
  const lang = rows[0]?.setting_value;
  return lang === 'fr' ? 'fr' : 'en';
}

module.exports = { getSettings, enabled, getUserLanguage };
