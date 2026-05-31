// Adds attachment columns to the messages table (image/file support in chat).
// Idempotent: skips columns that already exist (MySQL 8 has no IF NOT EXISTS
// for ADD COLUMN, so we catch the duplicate-column error).
require('dotenv').config();
const pool = require('../src/config/db');

const COLUMNS = [
  "ADD COLUMN attachment_type VARCHAR(10) NULL",  // 'image' | 'file'
  "ADD COLUMN attachment_name VARCHAR(255) NULL", // original file name
  "ADD COLUMN attachment_data LONGTEXT NULL",     // base64 data URL
];

(async () => {
  for (const c of COLUMNS) {
    try {
      await pool.query(`ALTER TABLE messages ${c}`);
      console.log('ok:', c);
    } catch (e) {
      console.log(`skip (${e.code}):`, c);
    }
  }
  await pool.end();
  console.log('done');
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
