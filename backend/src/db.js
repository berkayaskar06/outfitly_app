const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');
const { databasePath } = require('./config');

const dir = path.dirname(databasePath);
if (!fs.existsSync(dir)) {
  fs.mkdirSync(dir, { recursive: true });
}

const db = new Database(databasePath);
db.pragma('foreign_keys = ON');

db.exec(`
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS persons (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  label TEXT,
  image_path TEXT NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS products (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  category TEXT NOT NULL,
  image_path TEXT NOT NULL,
  style_tags TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS try_ons (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  person_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  fal_request_id TEXT,
  status TEXT NOT NULL,
  image_path TEXT,
  image_url TEXT,
  prompt TEXT,
  liked INTEGER,
  metadata TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(person_id) REFERENCES persons(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
);
`);

module.exports = db;
