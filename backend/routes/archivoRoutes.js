const express = require('express');
const router = express.Router();
const { subirArchivo } = require('../controllers/archivoController');
const { verificarToken } = require('../middlewares/authMiddleware');

// multipart/form-data con el campo "archivo" (JPG, PNG o WEBP, máx. 5 MB)
router.post('/', verificarToken, subirArchivo);

module.exports = router;
