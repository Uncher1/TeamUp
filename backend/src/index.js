require('dotenv').config();
const http    = require('http');
const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');
const morgan  = require('morgan');
const { initSocket } = require('./socket');

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

app.get('/',           (_req, res) => res.json({ name: 'TeamUp API', version: '0.1.0' }));
app.get('/api/health', (_req, res) => res.json({ ok: true }));

app.use('/api/auth',          require('./routes/auth'));
app.use('/api/users',         require('./routes/users'));
app.use('/api/projects',      require('./routes/projects'));
app.use('/api/posts',         require('./routes/posts'));
app.use('/api/matching',      require('./routes/matching'));
app.use('/api/conversations', require('./routes/conversations'));
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
