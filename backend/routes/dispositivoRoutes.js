const express = require('express');
const router = express.Router();
const { registrarDispositivo, eliminarDispositivo } = require('../controllers/dispositivoController');
const { verificarToken } = require('../middlewares/authMiddleware');

router.use(verificarToken);

router.post('/', registrarDispositivo);
router.delete('/', eliminarDispositivo);

module.exports = router;
