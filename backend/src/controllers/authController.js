const crypto = require('crypto');
const db = require('../db');

function loginOrRegister(req, res) {
  const { email, name } = req.body || {};

  if (!email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    return res.status(400).json({ message: 'Geçerli bir e-posta adresi giriniz.' });
  }
  if (!name || typeof name !== 'string' || !name.trim()) {
    return res.status(400).json({ message: 'İsim alanı zorunludur.' });
  }

  const trimmedName = name.trim();

  const existing = db.prepare('SELECT * FROM users WHERE email = ?').get(email);

  let user;
  if (existing) {
    db.prepare('UPDATE users SET name = ? WHERE id = ?').run(trimmedName, existing.id);
    user = { ...existing, name: trimmedName };
  } else {
    const result = db
      .prepare('INSERT INTO users (email, name) VALUES (?, ?)')
      .run(email, trimmedName);
    user = { id: result.lastInsertRowid, email, name: trimmedName };
  }

  const token = crypto.randomBytes(32).toString('hex');

  return res.json({
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
    },
    access_token: token,
  });
}

module.exports = {
  loginOrRegister,
};
