// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const pool = require('../config/db');

function parseOptions(raw) {
  if (Array.isArray(raw)) return raw;
  try { return JSON.parse(raw); } catch { return []; }
}

/** Public shape of a poll for a given viewer: options, vote counts, my vote(s). */
async function pollPublic(pollId, userId) {
  const [rows] = await pool.query(
    'SELECT id, question, options, multi FROM polls WHERE id = ?', [pollId]);
  if (!rows.length) return null;
  const options = parseOptions(rows[0].options);
  const counts = options.map(() => 0);
  let total = 0;
  const [votes] = await pool.query(
    'SELECT option_index, COUNT(*) AS c FROM poll_votes WHERE poll_id = ? GROUP BY option_index',
    [pollId]
  );
  for (const v of votes) {
    if (v.option_index < counts.length) counts[v.option_index] = Number(v.c);
    total += Number(v.c);
  }
  const [mine] = await pool.query(
    'SELECT option_index FROM poll_votes WHERE poll_id = ? AND user_id = ?',
    [pollId, userId]
  );
  const myVotes = mine.map((r) => r.option_index);
  return {
    id: rows[0].id,
    question: rows[0].question,
    options,
    counts,
    total,
    multi: rows[0].multi === 1,
    my_votes: myVotes,
    my_vote: myVotes.length ? myVotes[0] : null, // legacy single-vote field
  };
}

/** Attaches a `poll` object to any message rows of type 'poll'. */
async function enrichPolls(rows, userId) {
  for (const r of rows) {
    if (r.attachment_type === 'poll' && r.attachment_data) {
      r.poll = await pollPublic(Number(r.attachment_data), userId);
    }
  }
  return rows;
}

module.exports = { pollPublic, enrichPolls };
