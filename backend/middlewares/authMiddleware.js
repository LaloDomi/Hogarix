const jwt = require('jsonwebtoken');

const verificarToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Formato: "Bearer TOKEN"

    if (!token) {
        return res.status(401).json({
            ok: false,
            mensaje: 'Acceso denegado. No se proporcionó un token de autenticación.'
        });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.usuario = decoded; // Adjunta id_usuario y id_rol a la petición
        next();
    } catch (error) {
        return res.status(403).json({
            ok: false,
            mensaje: 'Token inválido o expirado.'
        });
    }
};

// Restringe una ruta a ciertos roles. Debe usarse después de verificarToken.
const verificarRol = (...rolesPermitidos) => (req, res, next) => {
    if (!rolesPermitidos.includes(Number(req.usuario.id_rol))) {
        return res.status(403).json({
            ok: false,
            mensaje: 'No tienes permisos para realizar esta acción.'
        });
    }
    next();
};

module.exports = {
    verificarToken,
    verificarRol
};