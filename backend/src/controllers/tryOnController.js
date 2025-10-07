const path = require('path');
const fs = require('fs');
const http = require('http');
const https = require('https');
const db = require('../db');
const falAiService = require('../services/falAiService');
const { publicUrlFor, publicUrlForRequest, storagePath, createUserDir } = require('../utils/storage');
const { resolveUserId } = require('../utils/users');
const { ulid } = require('ulid');

function getPerson(userId, personId) {
  return db
    .prepare('SELECT * FROM persons WHERE user_id = ? AND id = ?')
    .get(userId, personId);
}

function getProduct(userId, productId) {
  return db
    .prepare('SELECT * FROM products WHERE user_id = ? AND id = ?')
    .get(userId, productId);
}

function mapTryOnRow(row, req) {
  if (!row) return null;
  let imageUrl = row.image_url;
  let hostIsLocal = false;
  if (typeof imageUrl === 'string' && imageUrl) {
    try {
      const url = new URL(imageUrl);
      hostIsLocal = ['localhost', '127.0.0.1', '0.0.0.0'].includes(url.hostname);
    } catch (_e) {
      hostIsLocal = false;
    }
  }
  if ((!imageUrl || hostIsLocal) && row.image_path) {
    imageUrl = publicUrlForRequest(path.join(storagePath, row.image_path), req);
  }
  return {
    try_on_id: row.id,
    person_id: row.person_id,
    product_id: row.product_id,
    status: row.status,
    image_url: imageUrl ?? '',
    prompt: row.prompt,
    liked: row.liked === null ? null : Boolean(row.liked),
    created_at: row.created_at,
    metadata: row.metadata ? JSON.parse(row.metadata) : null,
  };
}

const { buildPrompt } = require('./promptController');

function looksLikeImageUrl(str) {
  if (typeof str !== 'string') return false;
  if (!/^https?:\/\//i.test(str)) return false;
  return /(\.png|\.jpg|\.jpeg|\.webp)(\?.*)?$/i.test(str) || /fal\.media\//i.test(str);
}

function deepFindImageUrl(obj) {
  if (!obj) return null;
  if (typeof obj === 'string' && looksLikeImageUrl(obj)) return obj;
  if (Array.isArray(obj)) {
    for (const item of obj) {
      const found = deepFindImageUrl(item);
      if (found) return found;
    }
    return null;
  }
  if (typeof obj === 'object') {
    // common fields
    if (obj.image_url && looksLikeImageUrl(obj.image_url)) return obj.image_url;
    if (obj.url && looksLikeImageUrl(obj.url)) return obj.url;
    if (obj.images && Array.isArray(obj.images)) {
      const c = deepFindImageUrl(obj.images);
      if (c) return c;
    }
    if (obj.output) {
      const c = deepFindImageUrl(obj.output);
      if (c) return c;
    }
    for (const key of Object.keys(obj)) {
      const val = obj[key];
      const found = deepFindImageUrl(val);
      if (found) return found;
    }
  }
  return null;
}

function isDataUrl(str) {
  return typeof str === 'string' && /^data:image\/(png|jpe?g|webp);base64,/i.test(str);
}

async function downloadToFile(url, targetPath, redirectsLeft = 3) {
  const client = url.startsWith('https') ? https : http;
  return new Promise((resolve, reject) => {
    const req = client.get(url, (res) => {
      if (res.statusCode && res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        if (redirectsLeft <= 0) {
          reject(new Error('Too many redirects'));
          return;
        }
        const redirectUrl = res.headers.location.startsWith('http')
          ? res.headers.location
          : new URL(res.headers.location, url).toString();
        res.resume();
        downloadToFile(redirectUrl, targetPath, redirectsLeft - 1).then(resolve).catch(reject);
        return;
      }
      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode}`));
        return;
      }
      const file = fs.createWriteStream(targetPath);
      res.pipe(file);
      file.on('finish', () => file.close(() => resolve(targetPath)));
      file.on('error', (err) => {
        fs.unlink(targetPath, () => reject(err));
      });
    });
    req.on('error', reject);
  });
}

async function persistImageForTryOn({ source, userId, tryOnId, req }) {
  // returns {relativePath, publicUrl}
  const dir = createUserDir(userId, 'try_ons');
  const fileName = `${tryOnId}.jpg`;
  const targetPath = path.join(dir, fileName);
  if (isDataUrl(source)) {
    const base64 = source.split(',')[1];
    const buffer = Buffer.from(base64, 'base64');
    fs.writeFileSync(targetPath, buffer);
  } else if (looksLikeImageUrl(source)) {
    await downloadToFile(source, targetPath);
  } else {
    throw new Error('Unsupported image source');
  }
  const relativePath = path.relative(storagePath, targetPath);
  return { relativePath, publicUrl: publicUrlForRequest(targetPath, req) };
}

async function store(req, res) {
  const { person_id: personId, product_id: productId } = req.body || {};

  if (!personId || !productId) {
    return res.status(400).json({ message: 'person_id ve product_id alanları zorunludur.' });
  }

  const user = resolveUserId(req.body.user_id || req.headers['x-user-id']);
  const person = getPerson(user.id, personId);
  if (!person) {
    return res.status(404).json({ message: 'Person kaydı bulunamadı.' });
  }
  const product = getProduct(user.id, productId);
  if (!product) {
    return res.status(404).json({ message: 'Ürün kaydı bulunamadı.' });
  }

  const personFilePath = path.join(storagePath, person.image_path);
  const productFilePath = path.join(storagePath, product.image_path);

  const prompt = buildPrompt(product.category ?? 'garment');

  let falResponse;
  try {
    falResponse = await falAiService.submitTryOn(personFilePath, productFilePath, prompt);
  } catch (error) {
    const detail = error.raw?.body ?? error.response?.data ?? error.message;
    // eslint-disable-next-line no-console
    console.error('fal.ai submit hatası', {
      message: error.message,
      responseStatus: error.response?.status,
      responseData: error.response?.data,
      detail,
      detailString: typeof detail === 'object' ? JSON.stringify(detail, null, 2) : detail,
    });
    return res.status(502).json({
      message: 'fal.ai servisine ulaşılamadı.',
      details: detail,
    });
  }

  const responsePayload = falResponse.response || falResponse;
  const tryOnId = ulid();
  let status = falResponse.status || 'completed'; // fal.subscribe zaten bekliyor
  // eslint-disable-next-line no-console
  console.log(`[TryOn ${tryOnId}] Created with fal.ai request_id: ${falResponse.request_id}`);
  // eslint-disable-next-line no-console
  console.log(`[TryOn ${tryOnId}] Response payload keys:`, Object.keys(responsePayload));
  
  // attempt early extraction
  const imageUrlCandidate = deepFindImageUrl(responsePayload);
  // eslint-disable-next-line no-console
  console.log(`[TryOn ${tryOnId}] Early image URL extraction: ${imageUrlCandidate ? imageUrlCandidate.substring(0, 80) + '...' : 'null'}`);
  
  let publicUrl = null;
  let relativePath = null;
  if (imageUrlCandidate) {
    try {
      // eslint-disable-next-line no-console
      console.log(`[TryOn ${tryOnId}] Persisting early image...`);
      const persisted = await persistImageForTryOn({
        source: imageUrlCandidate,
        userId: user.id,
        tryOnId,
        req,
      });
      publicUrl = persisted.publicUrl;
      relativePath = persisted.relativePath;
      status = 'completed';
      // eslint-disable-next-line no-console
      console.log(`[TryOn ${tryOnId}] Early image persisted: ${publicUrl}`);
    } catch (err) {
      // eslint-disable-next-line no-console
      console.log(`[TryOn ${tryOnId}] Early persist failed: ${err.message}`);
      status = 'failed';
      // ignore; will be retried in GET polling
    }
  } else {
    // eslint-disable-next-line no-console
    console.log(`[TryOn ${tryOnId}] WARNING: No image URL found in fal.ai response!`);
  }

  db.prepare(
    `INSERT INTO try_ons (
      id, user_id, person_id, product_id, fal_request_id, status, prompt, image_url, image_path, metadata
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  ).run(
    tryOnId,
    user.id,
    personId,
    productId,
    falResponse.request_id || falResponse.id || null,
    status,
    prompt,
    publicUrl || imageUrlCandidate || null,
    relativePath || null,
    JSON.stringify(falResponse),
  );

  const created = db.prepare('SELECT * FROM try_ons WHERE id = ?').get(tryOnId);
  
  // eslint-disable-next-line no-console
  console.log(`[TryOn ${tryOnId}] Initial status: ${status}, image_url: ${created.image_url ? 'SET' : 'NULL'}`);

  return res.status(202).json(mapTryOnRow(created, req));
}

async function show(req, res) {
  const { tryOn } = req.params;
  const row = db.prepare('SELECT * FROM try_ons WHERE id = ?').get(tryOn);
  if (!row) {
    return res.status(404).json({ message: 'Kayıt bulunamadı.' });
  }

  // eslint-disable-next-line no-console
  console.log(`[TryOn ${tryOn}] Current status: ${row.status}, has image_url: ${!!row.image_url}, fal_request_id: ${row.fal_request_id}`);

  if (row.fal_request_id && (row.status !== 'completed' || !row.image_url)) {
    try {
      // eslint-disable-next-line no-console
      console.log(`[TryOn ${tryOn}] Fetching result from fal.ai...`);
      const falResponse = await falAiService.fetchResult(row.fal_request_id);
      const responseStatus = falResponse.status || row.status;
      let imageSource = row.image_url;
      if (!imageSource) {
        const responsePayload = falResponse.response || falResponse;
        imageSource = deepFindImageUrl(responsePayload);
        // eslint-disable-next-line no-console
        console.log(`[TryOn ${tryOn}] Image source from fal.ai: ${imageSource ? imageSource.substring(0, 80) + '...' : 'null'}`);
      }
      let publicUrl = null;
      let relativePath = null;
      if (imageSource) {
        // eslint-disable-next-line no-console
        console.log(`[TryOn ${tryOn}] Persisting image to storage...`);
        const persisted = await persistImageForTryOn({
          source: imageSource,
          userId: row.user_id,
          tryOnId: row.id,
          req,
        });
        publicUrl = persisted.publicUrl;
        relativePath = persisted.relativePath;
        // eslint-disable-next-line no-console
        console.log(`[TryOn ${tryOn}] Image persisted. Public URL: ${publicUrl}`);
      }
      const completed = publicUrl ? 'completed' : responseStatus;

      db.prepare(
        'UPDATE try_ons SET status = ?, image_url = COALESCE(?, image_url), image_path = COALESCE(?, image_path), metadata = ? WHERE id = ?',
      ).run(
        completed,
        publicUrl,
        relativePath,
        JSON.stringify(falResponse),
        row.id,
      );

      row.status = completed;
      if (publicUrl) row.image_url = publicUrl;
      if (relativePath) row.image_path = relativePath;
      row.metadata = JSON.stringify(falResponse);
      
      // eslint-disable-next-line no-console
      console.log(`[TryOn ${tryOn}] Updated. Status: ${completed}, image_url: ${row.image_url ? 'SET' : 'NULL'}`);
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error(`[TryOn ${tryOn}] Error fetching result:`, error.message);
      return res.status(502).json({ message: 'fal.ai sonucu alınamadı.' });
    }
  }

  const result = mapTryOnRow(row, req);
  // eslint-disable-next-line no-console
  console.log(`[TryOn ${tryOn}] Returning result with image_url: ${result.image_url ? 'SET' : 'NULL'}`);
  return res.json(result);
}

function update(req, res) {
  const { tryOn } = req.params;
  const { liked } = req.body || {};

  if (typeof liked !== 'boolean') {
    return res.status(400).json({ message: 'liked alanı boolean olmalıdır.' });
  }

  const row = db.prepare('SELECT * FROM try_ons WHERE id = ?').get(tryOn);
  if (!row) {
    return res.status(404).json({ message: 'Kayıt bulunamadı.' });
  }

  db.prepare('UPDATE try_ons SET liked = ? WHERE id = ?').run(liked ? 1 : 0, tryOn);

  row.liked = liked ? 1 : 0;

  return res.json(mapTryOnRow(row, req));
}

module.exports = {
  store,
  show,
  update,
};
