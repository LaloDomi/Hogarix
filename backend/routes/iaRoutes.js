const express = require('express');
const router = express.Router();
const { asistente, mejorarTexto, resumenResenas } = require('../controllers/iaController');
const { verificarToken } = require('../middlewares/authMiddleware');

// Límite sencillo por usuario para no gastar la cuota gratis del proveedor:
// 20 peticiones cada 5 minutos.
const VENTANA_MS = 5 * 60 * 1000;
const MAXIMO = 20;
const uso = new Map();

const limitar = (req, res, next) => {
    const id = req.usuario.id_usuario;
    const ahora = Date.now();
    const recientes = (uso.get(id) || []).filter((t) => ahora - t < VENTANA_MS);
    if (recientes.length >= MAXIMO) {
        return res.status(429).json({
            ok: false,
            mensaje: 'Usaste mucho el asistente en poco tiempo. Espera unos minutos.'
        });
    }
    recientes.push(ahora);
    uso.set(id, recientes);
    // Limpieza para que el mapa no crezca sin fin.
    if (uso.size > 5000) {
        for (const [clave, tiempos] of uso) {
            if (!tiempos.some((t) => ahora - t < VENTANA_MS)) uso.delete(clave);
        }
    }
    next();
};

router.post('/asistente', verificarToken, limitar, asistente);
router.post('/mejorar-texto', verificarToken, limitar, mejorarTexto);
router.get('/resumen-resenas/:id_usuario', verificarToken, limitar, resumenResenas);

module.exports = router;
