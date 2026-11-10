const express = require('express');
const router = express.Router();
const { crearReporte } = require('../controllers/moderacionController');
const { verificarToken } = require('../middlewares/authMiddleware');

router.post('/', verificarToken, crearReporte);

module.exports = router;
