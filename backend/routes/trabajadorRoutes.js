const express = require('express');
const router = express.Router();
const {
    obtenerPerfilPublico,
    actualizarPerfil,
    crearServicio,
    actualizarServicio,
    eliminarServicio
} = require('../controllers/trabajadorController');
const { verificarToken, verificarRol } = require('../middlewares/authMiddleware');
const { ROLES } = require('../config/constantes');

const soloTrabajador = [verificarToken, verificarRol(ROLES.TRABAJADOR)];

// Rutas del trabajador autenticado (deben ir antes de '/:id_usuario')
router.put('/perfil', soloTrabajador, actualizarPerfil);
router.post('/servicios', soloTrabajador, crearServicio);
router.put('/servicios/:id_servicio', soloTrabajador, actualizarServicio);
router.delete('/servicios/:id_servicio', soloTrabajador, eliminarServicio);

// Ruta pública
router.get('/:id_usuario', obtenerPerfilPublico);

module.exports = router;
