const express = require('express');
const multer = require('multer');
const path = require('path');
const { ensureDir, prepareStorage, storagePath } = require('../utils/storage');
const authController = require('../controllers/authController');
const personController = require('../controllers/personController');
const productController = require('../controllers/productController');
const tryOnController = require('../controllers/tryOnController');
const promptController = require('../controllers/promptController');

prepareStorage();
const tempDir = path.join(storagePath, 'tmp');
ensureDir(tempDir);

const upload = multer({
  dest: tempDir,
  limits: { fileSize: 20 * 1024 * 1024 },
});

const router = express.Router();

router.post('/auth/login-or-register', authController.loginOrRegister);
router.post('/persons', upload.single('image'), personController.store);
router.post('/products', upload.single('image'), productController.store);
router.post('/try-on', tryOnController.store);
router.get('/try-on/:tryOn', tryOnController.show);
router.patch('/try-on/:tryOn', tryOnController.update);
router.get('/prompts', promptController.getPrompt);

module.exports = router;
