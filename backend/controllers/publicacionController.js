const PublicacionModel = require('../models/publicacionModel');
const { entero, texto, paginacion, esUrlImagen, manejarError, solicitudInvalida } = require('../utils/helpers');

const MAX_IMAGENES = 10;

const listarPublicaciones = async (req, res) => {
    try {
        let id_autor = null;
        if (req.query.id_usuario !== undefined) {
            id_autor = entero(req.query.id_usuario);
            if (!id_autor) return solicitudInvalida(res, 'id_usuario no es válido.');
        }

        const { limite, offset } = paginacion(req.query);
        const publicaciones = await PublicacionModel.listar({
            id_usuario_actual: req.usuario.id_usuario,
            id_autor,
            limite,
            offset
        });
        return res.status(200).json({ ok: true, total: publicaciones.length, data: publicaciones });
    } catch (error) {
        return manejarError(res, error, 'listarPublicaciones');
    }
};

const obtenerPublicacion = async (req, res) => {
    try {
        const id_publicacion = entero(req.params.id_publicacion);
        if (!id_publicacion) return solicitudInvalida(res, 'id_publicacion no es válido.');

        const [publicacion] = await PublicacionModel.listar({
            id_usuario_actual: req.usuario.id_usuario,
            id_publicacion,
            limite: 1,
            offset: 0
        });
        if (!publicacion) {
            return res.status(404).json({ ok: false, mensaje: 'Publicación no encontrada.' });
        }
        return res.status(200).json({ ok: true, data: publicacion });
    } catch (error) {
        return manejarError(res, error, 'obtenerPublicacion');
    }
};

const crearPublicacion = async (req, res) => {
    try {
        const body = req.body ?? {};
        const titulo = texto(body.titulo);
        const contenido = texto(body.contenido);
        const imagenes = body.imagenes ?? [];

        if (!titulo || !contenido) {
            return solicitudInvalida(res, 'titulo y contenido son obligatorios.');
        }
        if (titulo.length > 150) {
            return solicitudInvalida(res, 'El título no puede superar los 150 caracteres.');
        }
        if (!Array.isArray(imagenes) || imagenes.length > MAX_IMAGENES || !imagenes.every(esUrlImagen)) {
            return solicitudInvalida(
                res,
                `imagenes debe ser una lista de máximo ${MAX_IMAGENES} imágenes: rutas devueltas por POST /api/archivos o URLs https de hasta 255 caracteres.`
            );
        }

        const id_publicacion = await PublicacionModel.crear(req.usuario.id_usuario, titulo, contenido, imagenes);
        return res.status(201).json({ ok: true, mensaje: 'Publicación creada.', id_publicacion });
    } catch (error) {
        return manejarError(res, error, 'crearPublicacion');
    }
};

const eliminarPublicacion = async (req, res) => {
    try {
        const id_publicacion = entero(req.params.id_publicacion);
        if (!id_publicacion) return solicitudInvalida(res, 'id_publicacion no es válido.');

        await PublicacionModel.eliminar(req.usuario.id_usuario, id_publicacion);
        return res.status(200).json({ ok: true, mensaje: 'Publicación eliminada.' });
    } catch (error) {
        return manejarError(res, error, 'eliminarPublicacion');
    }
};

module.exports = {
    listarPublicaciones,
    obtenerPublicacion,
    crearPublicacion,
    eliminarPublicacion
};
