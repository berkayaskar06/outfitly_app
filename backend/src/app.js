const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const routes = require('./routes');
const { storagePath } = require('./utils/storage');

function createApp() {
  const app = express();

  // Respect X-Forwarded-* headers from Cloudflare tunnel for https and host
  app.set('trust proxy', true);

  app.use(helmet());
  app.use(cors());
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true }));
  app.use(morgan('dev'));

  app.use('/uploads', express.static(storagePath));

  app.use('/api', routes);

  app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
  });

  app.use((err, req, res, _next) => {
    // eslint-disable-next-line no-console
    console.error(err);
    res.status(500).json({ message: 'Beklenmeyen bir hata oluştu.' });
  });

  return app;
}

module.exports = createApp;
