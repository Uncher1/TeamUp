// TeamUp intro animation - shared draw logic (Canvas 2D).
// Used by BOTH the browser preview (preview.html) and the Node exporter
// (render.js), so what you preview is exactly what gets exported.
//
// The hexagon tracing mirrors the in-app splash (lib/screens/common/
// splash_screen.dart): hollow hexagon, vertices at left & right (flat top &
// bottom), round stroke ~11% of the logo box, revealed along its perimeter.

(function (root, factory) {
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = factory();
  } else {
    root.TeamUpIntro = factory();
  }
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  // ---- Brand constants (match the app) --------------------------------------
  const BG = '#F8FAFC'; // palette.background (light)
  const INDIGO = '#6366F1'; // primary seed
  const SLATE = '#0F172A'; // textPrimary (light)
  const WORD = 'TeamUp';
  const FONT_FAMILY = 'Outfit';

  // ---- Layout (tuned for a 1200x630 stage) ----------------------------------
  const HEX_BOX = 150; // logo bounding box (px)
  const FONT_SIZE = 112; // wordmark size (px)
  const GAP = 26; // space between logo and wordmark (px)
  const LETTER_SPACING = 4; // extra tracking between letters (px) - avoids "ea" crowding

  // ---- Timeline (seconds) ---------------------------------------------------
  const DRAW_END = 1.3; // hexagon finishes drawing
  const SLIDE_START = 1.3;
  const SLIDE_END = 1.72; // hexagon reaches its lockup position (snappier)
  const LETTERS_START = 1.58; // letters start BEFORE the slide fully settles
  const LETTER_STAGGER = 0.085; // delay between consecutive letters
  const LETTER_DUR = 0.45; // per-letter entrance duration
  const LETTERS_END = LETTERS_START + (WORD.length - 1) * LETTER_STAGGER + LETTER_DUR;
  const LOOP = 4.2; // total loop length (build + hold), then repeats

  // ---- Easing ---------------------------------------------------------------
  // Cubic-bezier solver to reproduce Flutter's Curves.easeInOut (0.42,0,0.58,1).
  function cubicBezier(p1x, p1y, p2x, p2y) {
    const cx = 3 * p1x;
    const bx = 3 * (p2x - p1x) - cx;
    const ax = 1 - cx - bx;
    const cy = 3 * p1y;
    const by = 3 * (p2y - p1y) - cy;
    const ay = 1 - cy - by;
    const sampleX = (t) => ((ax * t + bx) * t + cx) * t;
    const sampleY = (t) => ((ay * t + by) * t + cy) * t;
    const sampleDX = (t) => (3 * ax * t + 2 * bx) * t + cx;
    return function (x) {
      if (x <= 0) return 0;
      if (x >= 1) return 1;
      let t = x;
      for (let i = 0; i < 8; i++) {
        const xs = sampleX(t) - x;
        if (Math.abs(xs) < 1e-5) return sampleY(t);
        const d = sampleDX(t);
        if (Math.abs(d) < 1e-6) break;
        t -= xs / d;
      }
      // Bisection fallback.
      let lo = 0;
      let hi = 1;
      t = x;
      while (lo < hi) {
        const xs = sampleX(t);
        if (Math.abs(xs - x) < 1e-5) break;
        if (x > xs) lo = t;
        else hi = t;
        t = (lo + hi) / 2;
      }
      return sampleY(t);
    };
  }
  const easeInOut = cubicBezier(0.42, 0, 0.58, 1);
  const easeOut = cubicBezier(0.0, 0, 0.58, 1);
  function easeOutBack(x, overshoot) {
    const c1 = overshoot === undefined ? 1.70158 : overshoot; // higher = bouncier
    const c3 = c1 + 1;
    return 1 + c3 * Math.pow(x - 1, 3) + c1 * Math.pow(x - 1, 2);
  }
  const clamp01 = (v) => (v < 0 ? 0 : v > 1 ? 1 : v);

  // ---- Hexagon vertices (matches splash_screen.dart) ------------------------
  function hexVertices(cx, cy, r) {
    const pts = [];
    for (let i = 0; i < 6; i++) {
      const a = (Math.PI / 3) * i; // points at left & right, flat top & bottom
      pts.push([cx + r * Math.cos(a), cy + r * Math.sin(a)]);
    }
    return pts;
  }

  // Stroke the closed hexagon outline up to fraction `p` of its perimeter,
  // giving the "being hand-drawn" reveal.
  function drawHexagon(ctx, cx, cy, p) {
    const r = (HEX_BOX / 2) * 0.82; // leave room for the stroke
    const v = hexVertices(cx, cy, r);
    const loop = v.concat([v[0]]); // close the path
    // Edge lengths.
    const segs = [];
    let total = 0;
    for (let i = 0; i < loop.length - 1; i++) {
      const dx = loop[i + 1][0] - loop[i][0];
      const dy = loop[i + 1][1] - loop[i][1];
      const len = Math.hypot(dx, dy);
      segs.push(len);
      total += len;
    }
    ctx.save();
    ctx.strokeStyle = INDIGO;
    ctx.lineWidth = HEX_BOX * 0.11;
    ctx.lineJoin = 'round';
    ctx.lineCap = 'round';

    if (p >= 1) {
      ctx.beginPath();
      ctx.moveTo(loop[0][0], loop[0][1]);
      for (let i = 1; i < loop.length; i++) ctx.lineTo(loop[i][0], loop[i][1]);
      ctx.closePath();
      ctx.stroke();
      ctx.restore();
      return;
    }

    let target = total * clamp01(p);
    ctx.beginPath();
    ctx.moveTo(loop[0][0], loop[0][1]);
    for (let i = 0; i < segs.length; i++) {
      if (target <= 0) break;
      const len = segs[i];
      if (target >= len) {
        ctx.lineTo(loop[i + 1][0], loop[i + 1][1]);
        target -= len;
      } else {
        const f = target / len;
        const x = loop[i][0] + (loop[i + 1][0] - loop[i][0]) * f;
        const y = loop[i][1] + (loop[i + 1][1] - loop[i][1]) * f;
        ctx.lineTo(x, y);
        target = 0;
      }
    }
    ctx.stroke();
    ctx.restore();
  }

  // ---- Main frame -----------------------------------------------------------
  // Draws ONE frame for time `t` (seconds) onto ctx. width/height default to
  // the 1200x630 stage. Background is opaque (light).
  function drawFrame(ctx, t, opts) {
    opts = opts || {};
    const W = opts.width || 1200;
    const H = opts.height || 630;
    const tt = ((t % LOOP) + LOOP) % LOOP; // wrap into the loop

    // Background.
    ctx.fillStyle = BG;
    ctx.fillRect(0, 0, W, H);

    // Measure the wordmark so we can center the final logo+word lockup.
    ctx.font = '700 ' + FONT_SIZE + 'px "' + FONT_FAMILY + '"';
    ctx.textBaseline = 'alphabetic';
    ctx.textAlign = 'left';
    // Single, self-consistent metric: each glyph's isolated advance is used for
    // BOTH layout and drawing, so spacing stays uniform (no kerning mismatch).
    const letterW = [];
    for (let i = 0; i < WORD.length; i++) letterW.push(ctx.measureText(WORD[i]).width);
    const glyphsW = letterW.reduce((a, b) => a + b, 0);
    const textW = glyphsW + (WORD.length - 1) * LETTER_SPACING;
    const groupW = HEX_BOX + GAP + textW;
    const groupLeft = (W - groupW) / 2;
    const hexFinalCx = groupLeft + HEX_BOX / 2;
    const textLeft = groupLeft + HEX_BOX + GAP;
    const cy = H / 2;
    const baseline = cy + FONT_SIZE * 0.34; // optical vertical centering
    // Pre-compute each letter's horizontal center along the same basis.
    const letterCx = [];
    let cursor = textLeft;
    for (let i = 0; i < WORD.length; i++) {
      letterCx.push(cursor + letterW[i] / 2);
      cursor += letterW[i] + LETTER_SPACING;
    }

    // Hexagon x position + scale: centered alone, then a snappy slide to its
    // lockup spot with a punchy overshoot and a brief scale pulse for energy.
    let hexCx;
    let hexScale = 1;
    if (tt < SLIDE_START) {
      hexCx = W / 2;
    } else if (tt < SLIDE_END) {
      const sp = (tt - SLIDE_START) / (SLIDE_END - SLIDE_START); // 0..1
      const s = easeOutBack(sp, 2.8); // stronger overshoot = more dynamic
      hexCx = W / 2 + (hexFinalCx - W / 2) * s;
      hexScale = 1 + 0.1 * Math.sin(sp * Math.PI); // breathe out then back to 1
    } else {
      hexCx = hexFinalCx;
    }

    // Hexagon draw progress.
    const drawP = easeInOut(clamp01(tt / DRAW_END));
    ctx.save();
    ctx.translate(hexCx, cy);
    ctx.scale(hexScale, hexScale);
    ctx.translate(-hexCx, -cy);
    drawHexagon(ctx, hexCx, cy, drawP);
    ctx.restore();

    // Wordmark: letters pop in one by one with a slight bounce.
    if (tt >= LETTERS_START) {
      ctx.fillStyle = SLATE;
      ctx.font = '700 ' + FONT_SIZE + 'px "' + FONT_FAMILY + '"';
      ctx.textBaseline = 'alphabetic';
      ctx.textAlign = 'left';
      for (let i = 0; i < WORD.length; i++) {
        const localT = clamp01((tt - LETTERS_START - i * LETTER_STAGGER) / LETTER_DUR);
        if (localT <= 0) continue;
        const ease = easeOutBack(localT);
        const opacity = clamp01(localT * 2);
        const scale = 0.5 + 0.5 * ease; // pops slightly past 1, then settles
        const dy = (1 - ease) * 22; // rises from below, overshoots up, settles

        const lw = letterW[i];
        const pivotX = letterCx[i]; // fixed final center, consistent spacing

        ctx.save();
        ctx.globalAlpha = opacity;
        ctx.translate(pivotX, baseline + dy);
        ctx.scale(scale, scale);
        ctx.fillText(WORD[i], -lw / 2, 0);
        ctx.restore();
      }
    }
  }

  return {
    drawFrame,
    WIDTH: 1200,
    HEIGHT: 630,
    LOOP,
    FONT_FAMILY,
    BG,
  };
});
