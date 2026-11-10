const ResenaModel = require('../models/resenaModel');
const { entero, texto, paginacion, manejarError, solicitudInvalida } = require('../utils/helpers');

const crearResena = async (req, res) => {
    try {
        const body = req.body ?? {};
        const id_solicitud = entero(body.id_solicitud);
        if (!id_solicitud) return solicitudInvalida(res, 'id_solicitud es obligatorio.');

        if (!Number.isInteger(body.calificacion) || body.calificacion < 1 || body.calificacion > 5) {
            return solicitudInvalida(res, 'calificacion debe ser un entero entre 1 y 5.');
        }
        if (body.comentario !== undefined && body.comentario !== null && typeof body.comentario !== 'string') {
            return solicitudInvalida(res, 'comentario debe ser texto.');
        }
        const comentario = texto(body.comentario) || null;

        const id_resena = await ResenaModel.crear(req.usuario.id_usuario, id_solicitud, body.calificacion, comentario);
        return res.status(201).json({ ok: true, mensaje: 'Reseña creada.', id_resena });
    } catch (error) {
        return manejarError(res, error, 'crearResena');
    }
};

const listarResenasDeUsuario = async (req, res) => {
    try {
        const id_usuario = entero(req.params.id_usuario);
        if (!id_usuario) return solicitudInvalida(res, 'id_usuario no es válido.');

        const { limite, offset } = paginacion(req.query);
        const resenas = await ResenaModel.listarPorUsuario(id_usuario, limite, offset);
        return res.status(200).json({ ok: true, total: resenas.length, data: resenas });
    } catch (error) {
        return manejarError(res, error, 'listarResenasDeUsuario');
    }
};

module.exports = { crearResena, listarResenasDeUsuario };
