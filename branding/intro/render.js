// TeamUp intro - GIF exporter (pure Node, no ffmpeg).
// Renders the shared drawFrame() to an animated GIF via @napi-rs/canvas + gifenc.
//
//   node render.js [--fps=24] [--scale=1] [--colors=256]
//
// Output: teamup-intro.gif next to this file.

const fs = require('fs');
const path = require('path');
const { createCanvas, GlobalFonts } = require('@napi-rs/canvas');
const { GIFEncoder, quantize, applyPalette } = require('gifenc');
const intro = require('./frame.js');

// ---- Args -------------------------------------------------------------------
const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const m = a.replace(/^--/, '').split('=');
    return [m[0], m[1] === undefined ? true : m[1]];
  })
);
const FPS = Number(args.fps || 24);
const SCALE = Number(args.scale || 1);
const COLORS = Number(args.colors || 256);

// ---- Font (so the wordmark matches the app) ---------------------------------
const fontPath = path.join(__dirname, 'Outfit-Bold.ttf');
if (!fs.existsSync(fontPath)) {
  console.error('Missing Outfit-Bold.ttf next to render.js');
  process.exit(1);
}
GlobalFonts.registerFromPath(fontPath, 'Outfit');

// ---- Render -----------------------------------------------------------------
const W = intro.WIDTH;
const H = intro.HEIGHT;
const outW = Math.round(W * SCALE);
const outH = Math.round(H * SCALE);
const LOOP = intro.LOOP;
const frames = Math.round(LOOP * FPS);
const delay = Math.round(1000 / FPS); // ms per frame

const full = createCanvas(W, H);
const fctx = full.getContext('2d');
let out = full;
let octx = fctx;
if (SCALE !== 1) {
  out = createCanvas(outW, outH);
  octx = out.getContext('2d');
  octx.imageSmoothingEnabled = true;
}

const gif = GIFEncoder();
console.log(`Rendering ${frames} frames @ ${FPS}fps, ${outW}x${outH}, <=${COLORS} colors...`);

for (let i = 0; i < frames; i++) {
  const t = (i / FPS);
  intro.drawFrame(fctx, t, { width: W, height: H });
  if (SCALE !== 1) octx.drawImage(full, 0, 0, outW, outH);

  const { data } = octx.getImageData(0, 0, outW, outH);
  const palette = quantize(data, COLORS, { format: 'rgb565' });
  const index = applyPalette(data, palette, 'rgb565');
  gif.writeFrame(index, outW, outH, {
    palette,
    delay,
    repeat: i === 0 ? 0 : undefined, // 0 = loop forever (first frame only)
  });
  if (i % 15 === 0) process.stdout.write('.');
}
gif.finish();

const bytes = gif.bytes();
const outPath = path.join(__dirname, 'teamup-intro.gif');
fs.writeFileSync(outPath, bytes);
console.log(`\nWrote ${outPath} (${(bytes.length / 1024).toFixed(0)} Ko)`);
