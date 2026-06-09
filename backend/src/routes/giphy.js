// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const express = require('express');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

// Proxies GIF search/trending to GIPHY so the API key stays server-side (never
// in the public repo or the APK). Returns a trimmed list the app can render and
// send (a GIF is just a URL - we never store its bytes). The `messaging_non_clips`
// bundle returns plain animated-GIF renditions suited to chat (no video clips).
router.get('/search', authRequired, async (req, res) => {
  const key = process.env.GIPHY_API_KEY;
  if (!key) return res.status(503).json({ error: 'giphy not configured' });

  const q = String(req.query.q || '').trim().slice(0, 100);
  const limit = Math.min(30, Math.max(1, Number(req.query.limit) || 24));
  const base = q
    ? `https://api.giphy.com/v1/gifs/search?q=${encodeURIComponent(q)}&`
    : 'https://api.giphy.com/v1/gifs/trending?';
  const url = `${base}api_key=${key}&limit=${limit}&rating=pg-13&bundle=messaging_non_clips`;

  try {
    const r = await fetch(url);
    if (!r.ok) {
      const body = await r.text().catch(() => '');
      console.error(`[giphy] HTTP ${r.status} ${body.slice(0, 200)}`);
      return res.status(502).json({ error: 'giphy request failed' });
    }
    const data = await r.json();
    const gifs = (data.data || [])
      .map((g) => {
        const img = g.images || {};
        const u = img.fixed_width?.url || img.downsized?.url || img.original?.url;
        return { id: g.id, preview: u, gif: u };
      })
      .filter((g) => g.gif);
    res.json(gifs);
  } catch (e) {
    console.error(`[giphy] exception: ${e.message}`);
    res.status(502).json({ error: 'giphy request failed' });
  }
});

module.exports = router;
