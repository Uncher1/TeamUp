// Throwaway static server for previewing the intro animation locally.
// Hardened: path-traversal containment + loopback-only binding.
const http = require('http');
const fs = require('fs');
const path = require('path');
const root = __dirname;
const types = {
  '.html': 'text/html', '.js': 'text/javascript', '.ttf': 'font/ttf',
  '.gif': 'image/gif', '.webm': 'video/webm', '.png': 'image/png',
};
http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p === '/') p = '/preview.html';
  // Resolve and confirm the target stays inside root (block ../ traversal).
  const f = path.resolve(root, '.' + p);
  if (f !== root && !f.startsWith(root + path.sep)) {
    res.writeHead(403); res.end('forbidden'); return;
  }
  // Only serve known asset types.
  if (!types[path.extname(f)]) { res.writeHead(404); res.end('nf'); return; }
  fs.readFile(f, (e, d) => {
    if (e) { res.writeHead(404); res.end('nf'); return; }
    res.writeHead(200, { 'Content-Type': types[path.extname(f)] });
    res.end(d);
  });
}).listen(8777, '127.0.0.1', () => console.log('serving on 127.0.0.1:8777'));
