// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const express = require('express');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

// Always-available STUN (free, unlimited; handles same-network / simple NAT).
const STUN = [
  { urls: ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302'] },
];

// Returns the ICE servers the app should use for a 1:1 call. When a Cloudflare
// TURN key is configured (CF_TURN_KEY_ID + CF_TURN_API_TOKEN), short-lived TURN
// credentials are minted server-side so calls work on ANY network/country
// (NAT traversal via relay). Falls back to STUN-only if TURN isn't configured
// or the mint fails — the call still works on same-network/simple NATs.
router.get('/turn', authRequired, async (req, res) => {
  const keyId = process.env.CF_TURN_KEY_ID;
  const token = process.env.CF_TURN_API_TOKEN;
  if (!keyId || !token) {
    console.warn('[turn] CF_TURN_KEY_ID/CF_TURN_API_TOKEN not set → STUN-only');
    return res.json({ iceServers: STUN });
  }
  try {
    const r = await fetch(
      `https://rtc.live.cloudflare.com/v1/turn/keys/${keyId}/credentials/generate`,
      {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ ttl: 86400 }),
      }
    );
    if (!r.ok) {
      const body = await r.text().catch(() => '');
      console.error(`[turn] Cloudflare mint failed: HTTP ${r.status} ${body.slice(0, 300)} → STUN-only`);
      return res.json({ iceServers: STUN });
    }
    const data = await r.json();
    // Cloudflare returns { iceServers: { urls: [...], username, credential } }.
    const servers = [...STUN];
    if (data && data.iceServers) {
      servers.push(data.iceServers);
      const urls = data.iceServers.urls;
      console.log(`[turn] minted TURN OK (urls: ${Array.isArray(urls) ? urls.join(',') : urls})`);
    } else {
      console.error(`[turn] Cloudflare 200 but no iceServers in body: ${JSON.stringify(data).slice(0, 300)} → STUN-only`);
    }
    res.json({ iceServers: servers });
  } catch (e) {
    console.error(`[turn] mint exception: ${e.message} → STUN-only`);
    res.json({ iceServers: STUN });
  }
});

module.exports = router;
