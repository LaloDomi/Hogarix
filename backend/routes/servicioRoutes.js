const express = require('express');
const router = express.Router();
const { obtenerServiciosPorFiltro } = require('../controllers/servicioController');

router.get('/buscar', obtenerServiciosPorFiltro);

module.exports = router;