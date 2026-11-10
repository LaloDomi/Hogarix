const NotificacionModel = require('../models/notificacionModel');

// Crea una notificación dentro de la app. Nunca lanza error: si falla, solo
// se registra en consola para no tumbar la acción principal (crear una
// solicitud, cambiar su estado, etc.).
const notificar = async (id_usuario, datos) => {
    if (!id_usuario) return;
    try {
        await NotificacionModel.crear(id_usuario, datos);
    } catch (error) {
        console.error(`No se pudo crear la notificación (${datos?.tipo}) para el usuario ${id_usuario}:`, error.message);
    }
};

module.exports = { notificar };
