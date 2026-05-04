const bcrypt = require('bcryptjs');

const ROUNDS = 10;

const hash   = (password)             => bcrypt.hash(password, ROUNDS);
const verify = (password, storedHash) => bcrypt.compare(password, storedHash);

module.exports = { hash, verify };
