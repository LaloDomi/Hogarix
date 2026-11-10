const express = require('express');
const router = express.Router();
const { listarEventos, crearEvento, actualizarEvento, eliminarEvento } = require('../controllers/agendaController');
const { verificarToken } = require('../middlewares/authMiddleware');

// Agenda personal: ahora la pueden usar clientes y trabajadores.
router.use(verificarToken);

router.get('/', listarEventos);
router.post('/', crearEvento);
router.put('/:id_evento', actualizarEvento);
router.delete('/:id_evento', eliminarEvento);

module.exports = router;
