const db = require('../db');
const crypto = require('crypto');

function getDefaultUser() {
  const existing = db.prepare('SELECT * FROM users ORDER BY id ASC LIMIT 1').get();
  if (existing) {
    return existing;
  }
  const email = `demo+${crypto.randomBytes(4).toString('hex')}@virtualtryon.app`;
  const name = 'Demo Kullanıcı';
  const result = db.prepare('INSERT INTO users (email, name) VALUES (?, ?)').run(email, name);
  return { id: result.lastInsertRowid, email, name };
}

function resolveUserId(inputId) {
  if (!inputId) {
    return getDefaultUser();
  }
  const numericId = Number(inputId);
  const user = Number.isNaN(numericId)
    ? db.prepare('SELECT * FROM users WHERE id = ?').get(inputId)
    : db.prepare('SELECT * FROM users WHERE id = ?').get(numericId);
  if (user) {
    return user;
  }
  return getDefaultUser();
}

module.exports = {
  resolveUserId,
};
