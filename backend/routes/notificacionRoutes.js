const express = require('express');
const router = express.Router();
const {
    listarNotificaciones,
    contarNotificacionesNoLeidas,
    marcarNotificacionLeida,
    marcarTodasLeidas
} = require('../controllers/notificacionController');
const { verificarToken } = require('../middlewares/authMiddleware');

router.use(verificarToken);

router.get('/', listarNotificaciones);
router.get('/no-leidas', contarNotificacionesNoLeidas);
router.patch('/leidas', marcarTodasLeidas);
router.patch('/:id_notificacion/leida', marcarNotificacionLeida);

module.exports = router;
