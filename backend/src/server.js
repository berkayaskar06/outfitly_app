if (typeof globalThis.fetch === 'function' && typeof global.fetch !== 'function') {
  // Node 18+ exposes fetch on globalThis; copy to global for libraries using global.fetch
  global.fetch = (...args) => globalThis.fetch(...args);
}

if (typeof global.fetch !== 'function') {
  global.fetch = (...args) => import('node-fetch').then(({ default: fetch }) => fetch(...args));
}

const createApp = require('./app');
const { port, appUrl } = require('./config');

const app = createApp();

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`Sunucu ${appUrl} adresinde dinleniyor`);
});
