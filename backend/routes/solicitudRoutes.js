const express = require('express');
const router = express.Router();
const {
    crearSolicitud,
    listarSolicitudes,
    obtenerSolicitud,
    cambiarEstadoSolicitud
} = require('../controllers/solicitudController');
const { verificarToken, verificarRol } = require('../middlewares/authMiddleware');
const { ROLES } = require('../config/constantes');

router.use(verificarToken);

router.post('/', verificarRol(ROLES.CLIENTE), crearSolicitud);
router.get('/', listarSolicitudes);
router.get('/:id_solicitud', obtenerSolicitud);
router.patch('/:id_solicitud/estado', cambiarEstadoSolicitud);

module.exports = router;
