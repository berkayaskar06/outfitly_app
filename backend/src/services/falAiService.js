const fs = require('fs');
const path = require('path');
const fal = require('@fal-ai/serverless-client');
const sharp = require('sharp');
const { Blob } = require('buffer');
const { falAiKey, falAiModel } = require('../config');

async function fileToBlob(filePath) {
  const resolved = path.resolve(filePath);
  if (!fs.existsSync(resolved)) {
    throw new Error(`Dosya bulunamadı: ${resolved}`);
  }

  const buffer = await sharp(resolved)
    .rotate()
    .resize({ width: 1024, height: 1024, fit: 'inside', withoutEnlargement: true })
    .jpeg({ quality: 85 })
    .toBuffer();

  return new Blob([buffer], { type: 'image/jpeg' });
}

function normalizeModel(model) {
  const trimmed = model.trim().replace(/\/+$/g, '');
  return trimmed.startsWith('fal-ai/') ? trimmed : `fal-ai/${trimmed}`;
}

class FalAiService {
  constructor() {
    fal.config({ credentials: falAiKey });
  }

  async submitTryOn(personFilePath, productFilePath, prompt) {
    const model = normalizeModel(falAiModel);

    const uploadResults = await Promise.all([
      fileToBlob(personFilePath).then((blob) => fal.storage.upload(blob)),
      fileToBlob(productFilePath).then((blob) => fal.storage.upload(blob)),
    ]);

    const [personUrl, productUrl] = uploadResults.map((result) =>
      typeof result === 'string' ? result : result?.url,
    );

    if (!personUrl || !productUrl) {
      throw new Error('Upload edilen görseller için URL alınamadı.');
    }

    const response = await fal.subscribe(model, {
      input: {
        prompt,
        image_urls: [personUrl, productUrl],
      },
      logs: true,
    });

    // eslint-disable-next-line no-console
    console.log('📡 fal.ai response structure:', JSON.stringify({
      requestId: response.requestId,
      request_id: response.request_id,
      data: response.data ? Object.keys(response.data) : null,
      allKeys: Object.keys(response),
      hasImages: !!(response.images),
      imageCount: response.images ? response.images.length : 0,
    }, null, 2));

    // fal.subscribe() direkt sonucu döndürüyor, data wrapper'ı yok
    return {
      request_id: response.requestId || response.request_id || null,
      status: 'completed', // subscribe zaten bekliyor, completed olarak işaretle
      response: response, // data yok, direkt response kullan
    };
  }

  async fetchResult(requestId) {
    const model = normalizeModel(falAiModel);
    const result = await fal.queue.get(model, requestId);
    
    // eslint-disable-next-line no-console
    console.log(`📥 fal.ai queue result for ${requestId}:`, JSON.stringify({
      status: result.status,
      dataKeys: result.data ? Object.keys(result.data) : null,
      hasImages: !!(result.data?.images),
    }, null, 2));
    
    return {
      status: result.data?.status ?? result.status ?? 'completed',
      response: result.data,
    };
  }
}

module.exports = new FalAiService();
