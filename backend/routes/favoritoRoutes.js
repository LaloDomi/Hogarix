const express = require('express');
const router = express.Router();
const { listarFavoritos, agregarFavorito, quitarFavorito } = require('../controllers/favoritoController');
const { verificarToken, verificarRol } = require('../middlewares/authMiddleware');
const { ROLES } = require('../config/constantes');

router.use(verificarToken, verificarRol(ROLES.CLIENTE));

router.get('/', listarFavoritos);
router.post('/:id_trabajador', agregarFavorito);
router.delete('/:id_trabajador', quitarFavorito);

module.exports = router;
