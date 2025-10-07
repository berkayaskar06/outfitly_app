const path = require('path');
const fs = require('fs');
const { ulid } = require('ulid');
const db = require('../db');
const { publicUrlFor, storagePath, createUserDir } = require('../utils/storage');
const { resolveUserId } = require('../utils/users');

function store(req, res) {
  if (!req.file) {
    return res.status(400).json({ message: 'image alanı zorunludur.' });
  }

  const user = resolveUserId(req.body.user_id || req.headers['x-user-id']);
  const label = req.body.label ? String(req.body.label).trim() : null;
  const id = ulid();
  const targetDir = createUserDir(user.id, 'persons');
  const fileName = `${Date.now()}-${req.file.originalname.replace(/\s+/g, '_')}`;
  const targetPath = path.join(targetDir, fileName);
  fs.renameSync(req.file.path, targetPath);
  const relativePath = path.relative(storagePath, targetPath);

  db.prepare(
    'INSERT INTO persons (id, user_id, label, image_path) VALUES (?, ?, ?, ?)',
  ).run(id, user.id, label, relativePath);

  return res.status(201).json({
    person_id: id,
    image_url: publicUrlFor(targetPath),
    label,
  });
}

module.exports = {
  store,
};
