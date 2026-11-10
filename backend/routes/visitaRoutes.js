const express = require('express');
const router = express.Router();
const {
    listarVisitas,
    crearVisita,
    reprogramarVisita,
    cambiarEstadoVisita
} = require('../controllers/visitaController');
const { verificarToken } = require('../middlewares/authMiddleware');

router.use(verificarToken);

router.get('/', listarVisitas);
router.post('/', crearVisita);
router.put('/:id_visita', reprogramarVisita);
router.patch('/:id_visita/estado', cambiarEstadoVisita);

module.exports = router;
