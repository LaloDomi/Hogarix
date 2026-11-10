const TrabajadorModel = require('../models/trabajadorModel');
const { TIPOS_PAGO } = require('../config/constantes');
const { entero, texto, manejarError, solicitudInvalida } = require('../utils/helpers');

// Valida y normaliza el cuerpo de crear/actualizar servicio. Devuelve { error } o { datos }.
const validarServicio = (body) => {
    const id_categoria = entero(body.id_categoria);
    if (!id_categoria) return { error: 'id_categoria es obligatorio y debe ser un número válido.' };

    if (!TIPOS_PAGO.includes(body.tipo_pago)) {
        return { error: `tipo_pago debe ser uno de: ${TIPOS_PAGO.join(', ')}.` };
    }

    let precio_base = null;
    if (body.precio_base !== undefined && body.precio_base !== null) {
        if (typeof body.precio_base !== 'number' || !Number.isFinite(body.precio_base)
            || body.precio_base < 0 || body.precio_base > 99999999.99) {
            return { error: 'precio_base debe ser un número mayor o igual a 0.' };
        }
        precio_base = body.precio_base;
    }

    if (body.descripcion_servicio !== undefined && body.descripcion_servicio !== null
        && typeof body.descripcion_servicio !== 'string') {
        return { error: 'descripcion_servicio debe ser texto.' };
    }
    const descripcion_servicio = texto(body.descripcion_servicio) || null;

    return { datos: { id_categoria, tipo_pago: body.tipo_pago, precio_base, descripcion_servicio } };
};

const obtenerPerfilPublico = async (req, res) => {
    try {
        const id_usuario = entero(req.params.id_usuario);
        if (!id_usuario) return solicitudInvalida(res, 'id_usuario no es válido.');

        const perfil = await TrabajadorModel.obtenerPerfil(id_usuario);
        return res.status(200).json({ ok: true, data: perfil });
    } catch (error) {
        return manejarError(res, error, 'obtenerPerfilPublico');
    }
};

const actualizarPerfil = async (req, res) => {
    try {
        const { biografia, disponible } = req.body ?? {};

        if (biografia === undefined && disponible === undefined) {
            return solicitudInvalida(res, 'Envía biografia y/o disponible para actualizar.');
        }
        if (biografia !== undefined && typeof biografia !== 'string') {
            return solicitudInvalida(res, 'biografia debe ser texto.');
        }
        if (disponible !== undefined && typeof disponible !== 'boolean') {
            return solicitudInvalida(res, 'disponible debe ser true o false.');
        }

        const perfil = await TrabajadorModel.actualizarPerfil(
            req.usuario.id_usuario,
            biografia === undefined ? null : biografia.trim(),
            disponible === undefined ? null : disponible
        );
        return res.status(200).json({ ok: true, mensaje: 'Perfil actualizado.', data: perfil });
    } catch (error) {
        return manejarError(res, error, 'actualizarPerfil');
    }
};

const crearServicio = async (req, res) => {
    try {
        const { error, datos } = validarServicio(req.body ?? {});
        if (error) return solicitudInvalida(res, error);

        const id_servicio = await TrabajadorModel.crearServicio(req.usuario.id_usuario, datos);
        return res.status(201).json({ ok: true, mensaje: 'Servicio creado.', id_servicio });
    } catch (error) {
        return manejarError(res, error, 'crearServicio');
    }
};

const actualizarServicio = async (req, res) => {
    try {
        const id_servicio = entero(req.params.id_servicio);
        if (!id_servicio) return solicitudInvalida(res, 'id_servicio no es válido.');

        const { error, datos } = validarServicio(req.body ?? {});
        if (error) return solicitudInvalida(res, error);

        await TrabajadorModel.actualizarServicio(req.usuario.id_usuario, id_servicio, datos);
        return res.status(200).json({ ok: true, mensaje: 'Servicio actualizado.' });
    } catch (error) {
        return manejarError(res, error, 'actualizarServicio');
    }
};

const eliminarServicio = async (req, res) => {
    try {
        const id_servicio = entero(req.params.id_servicio);
        if (!id_servicio) return solicitudInvalida(res, 'id_servicio no es válido.');

        await TrabajadorModel.eliminarServicio(req.usuario.id_usuario, id_servicio);
        return res.status(200).json({ ok: true, mensaje: 'Servicio eliminado.' });
    } catch (error) {
        return manejarError(res, error, 'eliminarServicio');
    }
};

module.exports = {
    obtenerPerfilPublico,
    actualizarPerfil,
    crearServicio,
    actualizarServicio,
    eliminarServicio
};
