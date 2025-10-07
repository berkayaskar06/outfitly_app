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
  const category = req.body.category ? String(req.body.category).trim() : '';
  if (!category) {
    return res.status(400).json({ message: 'category alanı zorunludur.' });
  }

  let styleTags = [];
  if (Array.isArray(req.body.style_tags)) {
    styleTags = req.body.style_tags.map((tag) => String(tag).trim()).filter(Boolean);
  } else if (typeof req.body.style_tags === 'string') {
    try {
      const parsed = JSON.parse(req.body.style_tags);
      if (Array.isArray(parsed)) {
        styleTags = parsed.map((tag) => String(tag).trim()).filter(Boolean);
      }
    } catch (error) {
      styleTags = req.body.style_tags
        .split(',')
        .map((tag) => tag.trim())
        .filter(Boolean);
    }
  }

  const user = resolveUserId(req.body.user_id || req.headers['x-user-id']);
  const id = ulid();
  const targetDir = createUserDir(user.id, 'products');
  const fileName = `${Date.now()}-${req.file.originalname.replace(/\s+/g, '_')}`;
  const targetPath = path.join(targetDir, fileName);
  fs.renameSync(req.file.path, targetPath);
  const relativePath = path.relative(storagePath, targetPath);

  db.prepare(
    'INSERT INTO products (id, user_id, category, image_path, style_tags) VALUES (?, ?, ?, ?, ?)',
  ).run(id, user.id, category, relativePath, JSON.stringify(styleTags));

  return res.status(201).json({
    product_id: id,
    image_url: publicUrlFor(targetPath),
    category,
    style_tags: styleTags,
  });
}

module.exports = {
  store,
};
