const NotificacionModel = require('../models/notificacionModel');
const { entero, paginacion, manejarError, solicitudInvalida } = require('../utils/helpers');

// GET /api/notificaciones?no_leidas=true&pagina=&limite=
const listarNotificaciones = async (req, res) => {
    try {
        const soloNoLeidas = ['true', '1'].includes(String(req.query.no_leidas ?? '').toLowerCase());
        const { limite, offset } = paginacion(req.query);
        const notificaciones = await NotificacionModel.listar(req.usuario.id_usuario, soloNoLeidas, limite, offset);
        return res.status(200).json({ ok: true, total: notificaciones.length, data: notificaciones });
    } catch (error) {
        return manejarError(res, error, 'listarNotificaciones');
    }
};

// GET /api/notificaciones/no-leidas  -> número para la campanita
const contarNotificacionesNoLeidas = async (req, res) => {
    try {
        const total = await NotificacionModel.contarNoLeidas(req.usuario.id_usuario);
        return res.status(200).json({ ok: true, data: { total } });
    } catch (error) {
        return manejarError(res, error, 'contarNotificacionesNoLeidas');
    }
};

// PATCH /api/notificaciones/:id_notificacion/leida
const marcarNotificacionLeida = async (req, res) => {
    try {
        const id_notificacion = entero(req.params.id_notificacion);
        if (!id_notificacion) return solicitudInvalida(res, 'id_notificacion no es válido.');

        await NotificacionModel.marcarLeida(req.usuario.id_usuario, id_notificacion);
        return res.status(200).json({ ok: true, mensaje: 'Notificación marcada como leída.' });
    } catch (error) {
        return manejarError(res, error, 'marcarNotificacionLeida');
    }
};

// PATCH /api/notificaciones/leidas  -> marca todas
const marcarTodasLeidas = async (req, res) => {
    try {
        const actualizadas = await NotificacionModel.marcarTodasLeidas(req.usuario.id_usuario);
        return res.status(200).json({ ok: true, mensaje: 'Notificaciones marcadas como leídas.', data: { actualizadas } });
    } catch (error) {
        return manejarError(res, error, 'marcarTodasLeidas');
    }
};

module.exports = {
    listarNotificaciones,
    contarNotificacionesNoLeidas,
    marcarNotificacionLeida,
    marcarTodasLeidas
};
