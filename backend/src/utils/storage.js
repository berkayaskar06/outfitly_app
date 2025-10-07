const fs = require('fs');
const path = require('path');
const { storagePath, appUrl } = require('../config');

function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

function prepareStorage() {
  ensureDir(storagePath);
  ensureDir(path.join(storagePath, 'persons'));
  ensureDir(path.join(storagePath, 'products'));
}

function createUserDir(userId, type) {
  // allow persons, products, try_ons (default to persons)
  const allowed = new Set(['persons', 'products', 'try_ons']);
  const safeType = allowed.has(type) ? type : 'persons';
  const dir = path.join(storagePath, safeType, String(userId));
  ensureDir(dir);
  return dir;
}

function publicUrlFor(filePath) {
  const relative = path.relative(storagePath, filePath).split(path.sep).join('/');
  return new URL(`/uploads/${relative}`, appUrl).toString();
}

function baseFromConfigOrRequest(req) {
  try {
    const u = new URL(appUrl);
    const isLocal = ['localhost', '127.0.0.1', '0.0.0.0'].includes(u.hostname);
    if (!isLocal) return u.origin;

    const forwardedHost = (req?.headers?.['x-forwarded-host'] || '').toString().split(',')[0].trim();
    const host = forwardedHost || req?.headers?.host;
    const forwardedProto = (req?.headers?.['x-forwarded-proto'] || '').toString().split(',')[0].trim();
    const proto = forwardedProto || req?.protocol || (u.protocol?.replace(':', '') || 'http');
    if (host) return `${proto}://${host}`;
    return u.origin;
  } catch (_e) {
    if (req?.headers?.host) {
      const forwardedProto = (req.headers['x-forwarded-proto'] || '').toString().split(',')[0].trim();
      const proto = forwardedProto || req.protocol || 'http';
      return `${proto}://${req.headers.host}`;
    }
    return appUrl;
  }
}

function publicUrlForRequest(filePath, req) {
  const relative = path.relative(storagePath, filePath).split(path.sep).join('/');
  const base = baseFromConfigOrRequest(req);
  return new URL(`/uploads/${relative}`, base).toString();
}

module.exports = {
  storagePath,
  ensureDir,
  prepareStorage,
  createUserDir,
  publicUrlFor,
  publicUrlForRequest,
};
