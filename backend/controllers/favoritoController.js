const FavoritoModel = require('../models/favoritoModel');
const { entero, manejarError, solicitudInvalida } = require('../utils/helpers');

const listarFavoritos = async (req, res) => {
    try {
        const favoritos = await FavoritoModel.listar(req.usuario.id_usuario);
        return res.status(200).json({ ok: true, total: favoritos.length, data: favoritos });
    } catch (error) {
        return manejarError(res, error, 'listarFavoritos');
    }
};

const agregarFavorito = async (req, res) => {
    try {
        const id_trabajador = entero(req.params.id_trabajador);
        if (!id_trabajador) return solicitudInvalida(res, 'id_trabajador no es válido.');

        await FavoritoModel.agregar(req.usuario.id_usuario, id_trabajador);
        return res.status(200).json({ ok: true, mensaje: 'Trabajador agregado a favoritos.' });
    } catch (error) {
        return manejarError(res, error, 'agregarFavorito');
    }
};

const quitarFavorito = async (req, res) => {
    try {
        const id_trabajador = entero(req.params.id_trabajador);
        if (!id_trabajador) return solicitudInvalida(res, 'id_trabajador no es válido.');

        await FavoritoModel.quitar(req.usuario.id_usuario, id_trabajador);
        return res.status(200).json({ ok: true, mensaje: 'Trabajador quitado de favoritos.' });
    } catch (error) {
        return manejarError(res, error, 'quitarFavorito');
    }
};

module.exports = { listarFavoritos, agregarFavorito, quitarFavorito };
