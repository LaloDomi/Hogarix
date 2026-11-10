const express = require('express');
const router = express.Router();
const {
    listarConversaciones,
    iniciarConversacion,
    contarMensajesNoLeidos,
    listarMensajes,
    enviarMensaje,
    marcarConversacionLeida
} = require('../controllers/conversacionController');
const { verificarToken } = require('../middlewares/authMiddleware');

router.use(verificarToken);

router.get('/', listarConversaciones);
router.post('/', iniciarConversacion);
router.get('/no-leidos', contarMensajesNoLeidos);

router.get('/:id_conversacion/mensajes', listarMensajes);
router.post('/:id_conversacion/mensajes', enviarMensaje);
router.patch('/:id_conversacion/leida', marcarConversacionLeida);

module.exports = router;
