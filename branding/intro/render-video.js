// TeamUp intro - MP4 + WebM exporter.
// Renders the shared drawFrame() to PNG frames (via @napi-rs/canvas), then
// encodes them with ffmpeg into MP4 (H.264, best for WhatsApp) and WebM (VP9).
//
//   node render-video.js [--fps=30]
//
// Outputs teamup-intro.mp4 and teamup-intro.webm next to this file.

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { createCanvas, GlobalFonts } = require('@napi-rs/canvas');
const ffmpeg = require('@ffmpeg-installer/ffmpeg');
const intro = require('./frame.js');

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const m = a.replace(/^--/, '').split('=');
    return [m[0], m[1] === undefined ? true : m[1]];
  })
);
const FPS = Number(args.fps || 30);

GlobalFonts.registerFromPath(path.join(__dirname, 'Outfit-Bold.ttf'), 'Outfit');

const W = intro.WIDTH;
const H = intro.HEIGHT;
const LOOP = intro.LOOP;
const frames = Math.round(LOOP * FPS);

// ---- Render PNG frames to a temp dir ----------------------------------------
const tmp = path.join(__dirname, '.frames');
fs.rmSync(tmp, { recursive: true, force: true });
fs.mkdirSync(tmp, { recursive: true });

const canvas = createCanvas(W, H);
const ctx = canvas.getContext('2d');
console.log(`Rendering ${frames} PNG frames @ ${FPS}fps (${W}x${H})...`);
for (let i = 0; i < frames; i++) {
  intro.drawFrame(ctx, i / FPS, { width: W, height: H });
  const name = path.join(tmp, 'f' + String(i).padStart(4, '0') + '.png');
  fs.writeFileSync(name, canvas.toBuffer('image/png'));
  if (i % 15 === 0) process.stdout.write('.');
}
console.log('');

const input = path.join(tmp, 'f%04d.png');
const run = (label, ffArgs) => {
  console.log(`Encoding ${label}...`);
  execFileSync(ffmpeg.path, ffArgs, { stdio: ['ignore', 'ignore', 'inherit'] });
};

// ---- MP4 (H.264) - the format that plays everywhere incl. WhatsApp ----------
const mp4 = path.join(__dirname, 'teamup-intro.mp4');
run('MP4 (H.264)', [
  '-y', '-framerate', String(FPS), '-i', input,
  '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18',
  '-preset', 'slow', '-movflags', '+faststart', mp4,
]);

// ---- WebM (VP9) -------------------------------------------------------------
const webm = path.join(__dirname, 'teamup-intro.webm');
run('WebM (VP9)', [
  '-y', '-framerate', String(FPS), '-i', input,
  '-c:v', 'libvpx-vp9', '-b:v', '0', '-crf', '30', '-row-mt', '1', webm,
]);

// ---- Cleanup ----------------------------------------------------------------
fs.rmSync(tmp, { recursive: true, force: true });

const kb = (p) => (fs.statSync(p).size / 1024).toFixed(0);
console.log(`\nWrote:`);
console.log(`  ${mp4} (${kb(mp4)} Ko)`);
console.log(`  ${webm} (${kb(webm)} Ko)`);
