const VisitaModel = require('../models/visitaModel');
const { TIPOS_NOTIFICACION } = require('../config/constantes');
const { entero, fechaValida, manejarError, solicitudInvalida } = require('../utils/helpers');
const { notificar } = require('../utils/notificar');

const ESTADOS_VISITA = ['Confirmada', 'Cancelada', 'Realizada'];

const AVISOS = {
    Confirmada: { titulo: 'Visita confirmada', cuerpo: 'La otra persona confirmó la visita.' },
    Cancelada: { titulo: 'Visita cancelada', cuerpo: 'La visita fue cancelada.' },
    Realizada: { titulo: 'Visita realizada', cuerpo: 'El trabajador marcó la visita como realizada.' }
};

// Texto opcional: undefined/null -> null; '' borra al reprogramar.
const textoOpcional = (valor, max) => {
    if (valor === undefined || valor === null) return { valor: null };
    if (typeof valor !== 'string') return { error: true };
    const v = valor.trim();
    if (v.length > max) return { error: true };
    return { valor: v };
};

const validarHorario = (body) => {
    const fecha_inicio = fechaValida(body.fecha_inicio);
    const fecha_fin = fechaValida(body.fecha_fin);
    if (!fecha_inicio || !fecha_fin) {
        return { error: 'fecha_inicio y fecha_fin son obligatorias y deben ser fechas válidas.' };
    }
    const direccion = textoOpcional(body.direccion, 255);
    const notas = textoOpcional(body.notas, 1000);
    if (direccion.error) return { error: 'direccion debe ser texto de máximo 255 caracteres.' };
    if (notas.error) return { error: 'notas debe ser texto de máximo 1000 caracteres.' };
    return { datos: { fecha_inicio, fecha_fin, direccion: direccion.valor, notas: notas.valor } };
};

// GET /api/visitas?desde=&hasta=
const listarVisitas = async (req, res) => {
    try {
        const desde = fechaValida(req.query.desde);
        const hasta = fechaValida(req.query.hasta);
        if (!desde || !hasta) {
            return solicitudInvalida(res, 'desde y hasta son obligatorios y deben ser fechas válidas.');
        }
        const visitas = await VisitaModel.listar(req.usuario.id_usuario, desde, hasta);
        return res.status(200).json({ ok: true, total: visitas.length, data: visitas });
    } catch (error) {
        return manejarError(res, error, 'listarVisitas');
    }
};

// POST /api/visitas  { id_solicitud, fecha_inicio, fecha_fin, direccion?, notas? }
const crearVisita = async (req, res) => {
    try {
        const body = req.body ?? {};
        const id_solicitud = entero(body.id_solicitud);
        if (!id_solicitud) return solicitudInvalida(res, 'id_solicitud es obligatorio.');

        const { error, datos } = validarHorario(body);
        if (error) return solicitudInvalida(res, error);

        const r = await VisitaModel.crear(req.usuario.id_usuario, { id_solicitud, ...datos });
        await notificar(r?.id_otro, {
            tipo: TIPOS_NOTIFICACION.VISITA,
            titulo: 'Nueva visita propuesta',
            cuerpo: 'Te propusieron una visita de trabajo. Confírmala en tu calendario.',
            id_referencia: id_solicitud
        });
        return res.status(201).json({ ok: true, mensaje: 'Visita propuesta.', id_visita: r?.id_visita });
    } catch (error) {
        return manejarError(res, error, 'crearVisita');
    }
};

// PUT /api/visitas/:id_visita  (reprogramar)
const reprogramarVisita = async (req, res) => {
    try {
        const id_visita = entero(req.params.id_visita);
        if (!id_visita) return solicitudInvalida(res, 'id_visita no es válido.');

        const { error, datos } = validarHorario(req.body ?? {});
        if (error) return solicitudInvalida(res, error);

        const r = await VisitaModel.reprogramar(req.usuario.id_usuario, id_visita, datos);
        await notificar(r?.id_otro, {
            tipo: TIPOS_NOTIFICACION.VISITA,
            titulo: 'Visita reprogramada',
            cuerpo: 'Te propusieron un nuevo horario para la visita. Confírmalo en tu calendario.',
            id_referencia: id_visita
        });
        return res.status(200).json({ ok: true, mensaje: 'Visita reprogramada.' });
    } catch (error) {
        return manejarError(res, error, 'reprogramarVisita');
    }
};

// PATCH /api/visitas/:id_visita/estado  { estado }
const cambiarEstadoVisita = async (req, res) => {
    try {
        const id_visita = entero(req.params.id_visita);
        if (!id_visita) return solicitudInvalida(res, 'id_visita no es válido.');
        const { estado } = req.body ?? {};
        if (!ESTADOS_VISITA.includes(estado)) {
            return solicitudInvalida(res, `estado debe ser uno de: ${ESTADOS_VISITA.join(', ')}.`);
        }

        const r = await VisitaModel.cambiarEstado(req.usuario.id_usuario, id_visita, estado);
        await notificar(r?.id_otro, { tipo: TIPOS_NOTIFICACION.VISITA, ...AVISOS[estado], id_referencia: id_visita });
        return res.status(200).json({ ok: true, mensaje: `Visita ${estado.toLowerCase()}.` });
    } catch (error) {
        return manejarError(res, error, 'cambiarEstadoVisita');
    }
};

module.exports = { listarVisitas, crearVisita, reprogramarVisita, cambiarEstadoVisita };
