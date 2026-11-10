const PublicacionModel = require('../models/publicacionModel');
const { entero, texto, paginacion, manejarError, solicitudInvalida } = require('../utils/helpers');

const listarComentarios = async (req, res) => {
    try {
        const id_publicacion = entero(req.params.id_publicacion);
        if (!id_publicacion) return solicitudInvalida(res, 'id_publicacion no es válido.');

        const { limite, offset } = paginacion(req.query, 100, 50);
        const comentarios = await PublicacionModel.listarComentarios({
            id_publicacion,
            id_usuario_actual: req.usuario.id_usuario,
            limite,
            offset
        });
        return res.status(200).json({ ok: true, total: comentarios.length, data: comentarios });
    } catch (error) {
        return manejarError(res, error, 'listarComentarios');
    }
};

const crearComentario = async (req, res) => {
    try {
        const id_publicacion = entero(req.params.id_publicacion);
        if (!id_publicacion) return solicitudInvalida(res, 'id_publicacion no es válido.');

        const contenido = texto((req.body ?? {}).contenido);
        if (!contenido) return solicitudInvalida(res, 'contenido es obligatorio.');
        if (contenido.length > 1000) {
            return solicitudInvalida(res, 'El comentario no puede superar los 1000 caracteres.');
        }

        const id_comentario = await PublicacionModel.crearComentario(req.usuario.id_usuario, id_publicacion, contenido);
        return res.status(201).json({ ok: true, mensaje: 'Comentario creado.', id_comentario });
    } catch (error) {
        return manejarError(res, error, 'crearComentario');
    }
};

const eliminarComentario = async (req, res) => {
    try {
        const id_publicacion = entero(req.params.id_publicacion);
        const id_comentario = entero(req.params.id_comentario);
        if (!id_publicacion || !id_comentario) {
            return solicitudInvalida(res, 'id_publicacion o id_comentario no es válido.');
        }

        await PublicacionModel.eliminarComentario(req.usuario.id_usuario, id_publicacion, id_comentario);
        return res.status(200).json({ ok: true, mensaje: 'Comentario eliminado.' });
    } catch (error) {
        return manejarError(res, error, 'eliminarComentario');
    }
};

const darLike = async (req, res) => {
    try {
        const id_publicacion = entero(req.params.id_publicacion);
        if (!id_publicacion) return solicitudInvalida(res, 'id_publicacion no es válido.');

        const total_likes = await PublicacionModel.agregarLike(req.usuario.id_usuario, id_publicacion);
        return res.status(200).json({ ok: true, total_likes });
    } catch (error) {
        return manejarError(res, error, 'darLike');
    }
};

const quitarLike = async (req, res) => {
    try {
        const id_publicacion = entero(req.params.id_publicacion);
        if (!id_publicacion) return solicitudInvalida(res, 'id_publicacion no es válido.');

        const total_likes = await PublicacionModel.quitarLike(req.usuario.id_usuario, id_publicacion);
        return res.status(200).json({ ok: true, total_likes });
    } catch (error) {
        return manejarError(res, error, 'quitarLike');
    }
};

module.exports = {
    listarComentarios,
    crearComentario,
    eliminarComentario,
    darLike,
    quitarLike
};
