const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     Number(process.env.DB_PORT) || 3306,
  user:     process.env.DB_USER     || 'teamup',
  password: process.env.DB_PASSWORD ?? 'teamup',
  database: process.env.DB_NAME     || 'teamup',
  waitForConnections: true,
  connectionLimit: 10,
  timezone: 'Z'
});

module.exports = pool;
