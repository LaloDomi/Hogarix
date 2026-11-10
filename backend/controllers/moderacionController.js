const ModeracionModel = require('../models/moderacionModel');
const { entero, texto, manejarError, solicitudInvalida } = require('../utils/helpers');

const crearReporte = async (req, res) => {
    try {
        const body = req.body ?? {};
        const id_usuario_reportado = body.id_usuario_reportado === undefined || body.id_usuario_reportado === null
            ? null : entero(body.id_usuario_reportado);
        const id_publicacion = body.id_publicacion === undefined || body.id_publicacion === null
            ? null : entero(body.id_publicacion);

        if (!id_usuario_reportado && !id_publicacion) {
            return solicitudInvalida(res, 'Indica id_usuario_reportado y/o id_publicacion a reportar.');
        }

        const motivo = texto(body.motivo);
        if (!motivo || motivo.length > 255) {
            return solicitudInvalida(res, 'motivo es obligatorio y no puede superar los 255 caracteres.');
        }
        if (body.detalle !== undefined && body.detalle !== null && typeof body.detalle !== 'string') {
            return solicitudInvalida(res, 'detalle debe ser texto.');
        }

        const id_reporte = await ModeracionModel.crearReporte(req.usuario.id_usuario, {
            id_usuario_reportado,
            id_publicacion,
            motivo,
            detalle: texto(body.detalle) || null
        });
        return res.status(201).json({ ok: true, mensaje: 'Reporte enviado. Gracias por ayudarnos a mantener la comunidad segura.', id_reporte });
    } catch (error) {
        return manejarError(res, error, 'crearReporte');
    }
};

const listarBloqueos = async (req, res) => {
    try {
        const bloqueos = await ModeracionModel.listarBloqueos(req.usuario.id_usuario);
        return res.status(200).json({ ok: true, total: bloqueos.length, data: bloqueos });
    } catch (error) {
        return manejarError(res, error, 'listarBloqueos');
    }
};

const bloquearUsuario = async (req, res) => {
    try {
        const id_bloqueado = entero(req.params.id_usuario);
        if (!id_bloqueado) return solicitudInvalida(res, 'id_usuario no es válido.');

        await ModeracionModel.bloquear(req.usuario.id_usuario, id_bloqueado);
        return res.status(200).json({ ok: true, mensaje: 'Usuario bloqueado.' });
    } catch (error) {
        return manejarError(res, error, 'bloquearUsuario');
    }
};

const desbloquearUsuario = async (req, res) => {
    try {
        const id_bloqueado = entero(req.params.id_usuario);
        if (!id_bloqueado) return solicitudInvalida(res, 'id_usuario no es válido.');

        await ModeracionModel.desbloquear(req.usuario.id_usuario, id_bloqueado);
        return res.status(200).json({ ok: true, mensaje: 'Usuario desbloqueado.' });
    } catch (error) {
        return manejarError(res, error, 'desbloquearUsuario');
    }
};

module.exports = { crearReporte, listarBloqueos, bloquearUsuario, desbloquearUsuario };
