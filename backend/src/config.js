const path = require('path');
const fs = require('fs');
const dotenv = require('dotenv');

const candidatePaths = [
  path.resolve(process.cwd(), '.env'),
  path.resolve(__dirname, '..', '.env'),
];

let loaded = false;
for (const envPath of candidatePaths) {
  if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath });
    loaded = true;
    break;
  }
}

if (!loaded) {
  dotenv.config();
}

const port = process.env.PORT || 3000;
const appUrl = process.env.APP_URL || `http://localhost:${port}`;
const databasePath = process.env.DATABASE_PATH
  ? path.resolve(process.cwd(), process.env.DATABASE_PATH)
  : path.resolve(process.cwd(), 'data', 'database.sqlite');
const storagePath = process.env.STORAGE_PATH
  ? path.resolve(process.cwd(), process.env.STORAGE_PATH)
  : path.resolve(process.cwd(), 'uploads');

const fallbackFalKey =
  'ff49ff7e-a12f-4e35-acce-d3b9d39129f9:16bd493b0292b6929eda58f1aa545263';

module.exports = {
  port,
  appUrl,
  databasePath,
  storagePath,
  falAiKey: process.env.FALAI_API_KEY || fallbackFalKey,
  falAiModel:
    process.env.FALAI_MODEL || 'fal-ai/gemini-25-flash-image/edit',
};
