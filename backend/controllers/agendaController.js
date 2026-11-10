const AgendaModel = require('../models/agendaModel');
const { entero, texto, fechaValida, manejarError, solicitudInvalida } = require('../utils/helpers');

// Valida y normaliza el cuerpo de crear/actualizar evento. Devuelve { error } o { datos }.
const validarEvento = (body) => {
    const titulo = texto(body.titulo);
    if (!titulo || titulo.length > 150) {
        return { error: 'titulo es obligatorio y no puede superar los 150 caracteres.' };
    }

    const fecha_inicio = fechaValida(body.fecha_inicio);
    const fecha_fin = fechaValida(body.fecha_fin);
    if (!fecha_inicio || !fecha_fin) {
        return { error: 'fecha_inicio y fecha_fin son obligatorias y deben ser fechas válidas.' };
    }

    if (body.descripcion !== undefined && body.descripcion !== null && typeof body.descripcion !== 'string') {
        return { error: 'descripcion debe ser texto.' };
    }
    const descripcion = texto(body.descripcion) || null;

    return { datos: { titulo, descripcion, fecha_inicio, fecha_fin } };
};

const listarEventos = async (req, res) => {
    try {
        const desde = fechaValida(req.query.desde);
        const hasta = fechaValida(req.query.hasta);
        if (!desde || !hasta) {
            return solicitudInvalida(res, 'desde y hasta son obligatorios y deben ser fechas válidas.');
        }

        const eventos = await AgendaModel.listar(req.usuario.id_usuario, desde, hasta);
        return res.status(200).json({ ok: true, total: eventos.length, data: eventos });
    } catch (error) {
        return manejarError(res, error, 'listarEventos');
    }
};

const crearEvento = async (req, res) => {
    try {
        const { error, datos } = validarEvento(req.body ?? {});
        if (error) return solicitudInvalida(res, error);

        const id_evento = await AgendaModel.crear(req.usuario.id_usuario, datos);
        return res.status(201).json({ ok: true, mensaje: 'Evento creado.', id_evento });
    } catch (error) {
        return manejarError(res, error, 'crearEvento');
    }
};

const actualizarEvento = async (req, res) => {
    try {
        const id_evento = entero(req.params.id_evento);
        if (!id_evento) return solicitudInvalida(res, 'id_evento no es válido.');

        const { error, datos } = validarEvento(req.body ?? {});
        if (error) return solicitudInvalida(res, error);

        await AgendaModel.actualizar(req.usuario.id_usuario, id_evento, datos);
        return res.status(200).json({ ok: true, mensaje: 'Evento actualizado.' });
    } catch (error) {
        return manejarError(res, error, 'actualizarEvento');
    }
};

const eliminarEvento = async (req, res) => {
    try {
        const id_evento = entero(req.params.id_evento);
        if (!id_evento) return solicitudInvalida(res, 'id_evento no es válido.');

        await AgendaModel.eliminar(req.usuario.id_usuario, id_evento);
        return res.status(200).json({ ok: true, mensaje: 'Evento eliminado.' });
    } catch (error) {
        return manejarError(res, error, 'eliminarEvento');
    }
};

module.exports = { listarEventos, crearEvento, actualizarEvento, eliminarEvento };
