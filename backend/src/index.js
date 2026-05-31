require('dotenv').config();
const http    = require('http');
const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');
const morgan  = require('morgan');
const rateLimit = require('express-rate-limit');
const { initSocket } = require('./socket');
const pool = require('./config/db');

// Throttle auth endpoints (login/register/verify/resend/google) to slow down
// brute-force + e-mail spam. Generous enough not to bother real users.
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 40,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many attempts, please try again later.' },
});

const app = express();
// Trust one reverse proxy (the hosting platform) so rate-limit sees real IPs.
app.set('trust proxy', 1);
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

app.get('/',           (_req, res) => res.json({ name: 'TeamUp API', version: '0.1.0' }));
// Health check that also touches the DB — doubles as a keep-alive ping to stop
// the free host + managed DB from idling to sleep.
app.get('/api/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ ok: true, db: true });
  } catch (e) {
    res.status(503).json({ ok: false, db: false });
  }
});

app.use('/api/auth',          authLimiter, require('./routes/auth'));
app.use('/api/users',         require('./routes/users'));
app.use('/api/projects',      require('./routes/projects'));
app.use('/api/posts',         require('./routes/posts'));
app.use('/api/matching',      require('./routes/matching'));
app.use('/api/conversations', require('./routes/conversations'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/admin',         require('./routes/admin'));
app.use('/api',               require('./routes/lookup'));

app.use((err, _req, res, _next) => {
  console.error(err);
  if (res.headersSent) return;
  res.status(500).json({ error: 'internal server error' });
});

const server = http.createServer(app);
const io = initSocket(server);
app.set('io', io); // let REST handlers broadcast realtime events

const port = Number(process.env.PORT) || 3000;
server.listen(port, () => console.log(`TeamUp API listening on http://localhost:${port}`));
