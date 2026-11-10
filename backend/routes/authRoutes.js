const express = require('express');
const router = express.Router();
const {
    registrar,
    login,
    obtenerPerfil,
    actualizarPerfil,
    loginGoogle,
    loginFacebook,
    enviarCodigoCorreo,
    restablecerContrasena,
    accederConCodigo,
    cambiarCorreo,
    cambiarContrasena
} = require('../controllers/authController');
const { verificarToken } = require('../middlewares/authMiddleware');

// Rutas Públicas
router.post('/registro', registrar);
router.post('/login', login);
router.post('/google', loginGoogle);
router.post('/facebook', loginFacebook);

// Códigos por correo: restablecer contraseña y entrar sin contraseña
router.post('/codigo', enviarCodigoCorreo);
router.post('/codigo/verificar', accederConCodigo);
router.post('/contrasena/restablecer', restablecerContrasena);

// Rutas Protegidas (requieren token)
router.get('/perfil', verificarToken, obtenerPerfil);
router.put('/perfil', verificarToken, actualizarPerfil);
router.put('/correo', verificarToken, cambiarCorreo);
router.put('/contrasena', verificarToken, cambiarContrasena);

module.exports = router;
