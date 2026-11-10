const express = require('express');
const router = express.Router();
const { crearResena, listarResenasDeUsuario } = require('../controllers/resenaController');
const { verificarToken } = require('../middlewares/authMiddleware');

router.post('/', verificarToken, crearResena);

// Ruta pública: reseñas recibidas por un usuario
router.get('/usuario/:id_usuario', listarResenasDeUsuario);

module.exports = router;
