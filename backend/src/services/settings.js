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

module.exports = { getSettings, enabled };
