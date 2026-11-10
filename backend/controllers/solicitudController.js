const SolicitudModel = require('../models/solicitudModel');
const { TIPOS_PAGO, ESTADOS_SOLICITUD, TIPOS_NOTIFICACION } = require('../config/constantes');
const { entero, paginacion, manejarError, solicitudInvalida } = require('../utils/helpers');
const { notificar } = require('../utils/notificar');

const AVISOS_ESTADO = {
    Aceptado: { titulo: 'Solicitud aceptada', cuerpo: 'El trabajador aceptó tu solicitud.' },
    Rechazado: { titulo: 'Solicitud rechazada', cuerpo: 'El trabajador rechazó tu solicitud.' },
    Completado: { titulo: 'Trabajo completado', cuerpo: 'La solicitud se marcó como completada. Ya puedes dejar tu reseña.' },
    Cancelado: { titulo: 'Solicitud cancelada', cuerpo: 'La solicitud fue cancelada.' }
};

// Devuelve el id de la otra parte de la solicitud (cliente <-> trabajador).
const otraParte = (fila, id_usuario) => {
    const cliente = Number(fila?.id_cliente);
    const trabajador = Number(fila?.id_trabajador);
    if (!cliente || !trabajador) return null;
    if (id_usuario === cliente) return trabajador;
    if (id_usuario === trabajador) return cliente;
    return null;
};

// Avisa a la otra parte del cambio de estado. Si falla, no afecta la respuesta.
const notificarCambioEstado = async (id_usuario, id_solicitud, estado, resultado) => {
    const aviso = AVISOS_ESTADO[estado];
    if (!aviso) return;
    try {
        let destinatario = otraParte(resultado, id_usuario);
        if (!destinatario) {
            const [fila] = await SolicitudModel.listar({ id_usuario, id_solicitud, limite: 1, offset: 0 });
            destinatario = otraParte(fila, id_usuario);
        }
        await notificar(destinatario, {
            tipo: TIPOS_NOTIFICACION.SOLICITUD_ESTADO,
            titulo: aviso.titulo,
            cuerpo: aviso.cuerpo,
            id_referencia: id_solicitud
        });
    } catch (error) {
        console.error('No se pudo notificar el cambio de estado:', error.message);
    }
};

const crearSolicitud = async (req, res) => {
    try {
        const body = req.body ?? {};
        const id_trabajador = entero(body.id_trabajador);
        const id_categoria = entero(body.id_categoria);

        if (!id_trabajador || !id_categoria) {
            return solicitudInvalida(res, 'id_trabajador e id_categoria son obligatorios.');
        }
        if (!TIPOS_PAGO.includes(body.tipo_pago_acordado)) {
            return solicitudInvalida(res, `tipo_pago_acordado debe ser uno de: ${TIPOS_PAGO.join(', ')}.`);
        }

        let monto_estimado = null;
        if (body.monto_estimado !== undefined && body.monto_estimado !== null) {
            if (typeof body.monto_estimado !== 'number' || !Number.isFinite(body.monto_estimado)
                || body.monto_estimado < 0 || body.monto_estimado > 99999999.99) {
                return solicitudInvalida(res, 'monto_estimado debe ser un número mayor o igual a 0.');
            }
            monto_estimado = body.monto_estimado;
        }

        const id_solicitud = await SolicitudModel.crear(req.usuario.id_usuario, {
            id_trabajador,
            id_categoria,
            tipo_pago_acordado: body.tipo_pago_acordado,
            monto_estimado
        });

        await notificar(id_trabajador, {
            tipo: TIPOS_NOTIFICACION.SOLICITUD_NUEVA,
            titulo: 'Nueva solicitud de trabajo',
            cuerpo: 'Un cliente te envió una solicitud. Revísala para aceptarla o rechazarla.',
            id_referencia: id_solicitud
        });

        return res.status(201).json({ ok: true, mensaje: 'Solicitud enviada.', id_solicitud });
    } catch (error) {
        return manejarError(res, error, 'crearSolicitud');
    }
};

const listarSolicitudes = async (req, res) => {
    try {
        let estado = null;
        if (req.query.estado !== undefined) {
            if (!ESTADOS_SOLICITUD.includes(req.query.estado)) {
                return solicitudInvalida(res, `estado debe ser uno de: ${ESTADOS_SOLICITUD.join(', ')}.`);
            }
            estado = req.query.estado;
        }

        const { limite, offset } = paginacion(req.query);
        const solicitudes = await SolicitudModel.listar({
            id_usuario: req.usuario.id_usuario,
            estado,
            limite,
            offset
        });
        return res.status(200).json({ ok: true, total: solicitudes.length, data: solicitudes });
    } catch (error) {
        return manejarError(res, error, 'listarSolicitudes');
    }
};

const obtenerSolicitud = async (req, res) => {
    try {
        const id_solicitud = entero(req.params.id_solicitud);
        if (!id_solicitud) return solicitudInvalida(res, 'id_solicitud no es válido.');

        const [solicitud] = await SolicitudModel.listar({
            id_usuario: req.usuario.id_usuario,
            id_solicitud,
            limite: 1,
            offset: 0
        });
        if (!solicitud) {
            return res.status(404).json({ ok: false, mensaje: 'Solicitud no encontrada.' });
        }
        return res.status(200).json({ ok: true, data: solicitud });
    } catch (error) {
        return manejarError(res, error, 'obtenerSolicitud');
    }
};

const cambiarEstadoSolicitud = async (req, res) => {
    try {
        const id_solicitud = entero(req.params.id_solicitud);
        if (!id_solicitud) return solicitudInvalida(res, 'id_solicitud no es válido.');

        const { estado } = req.body ?? {};
        if (!ESTADOS_SOLICITUD.includes(estado)) {
            return solicitudInvalida(res, `estado debe ser uno de: ${ESTADOS_SOLICITUD.join(', ')}.`);
        }

        const resultado = await SolicitudModel.cambiarEstado(req.usuario.id_usuario, id_solicitud, estado);
        await notificarCambioEstado(req.usuario.id_usuario, id_solicitud, estado, resultado);
        return res.status(200).json({ ok: true, mensaje: `Solicitud ${estado.toLowerCase()}.`, data: resultado });
    } catch (error) {
        return manejarError(res, error, 'cambiarEstadoSolicitud');
    }
};

module.exports = {
    crearSolicitud,
    listarSolicitudes,
    obtenerSolicitud,
    cambiarEstadoSolicitud
};
