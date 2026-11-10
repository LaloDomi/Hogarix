const ConversacionModel = require('../models/conversacionModel');
const { CHAT } = require('../config/constantes');
const { entero, texto, paginacion, esUrlImagen, manejarError, solicitudInvalida } = require('../utils/helpers');

// Parámetro de query opcional: undefined -> null; inválido -> false.
const idOpcional = (valor) => (valor === undefined ? null : entero(valor) || false);

// GET /api/conversaciones?pagina=&limite=
const listarConversaciones = async (req, res) => {
    try {
        const { limite, offset } = paginacion(req.query);
        const conversaciones = await ConversacionModel.listar(req.usuario.id_usuario, limite, offset);
        return res.status(200).json({ ok: true, total: conversaciones.length, data: conversaciones });
    } catch (error) {
        return manejarError(res, error, 'listarConversaciones');
    }
};

// POST /api/conversaciones  { id_usuario }  -> abre (o reutiliza) el chat con ese usuario
const iniciarConversacion = async (req, res) => {
    try {
        const id_otro = entero(req.body?.id_usuario);
        if (!id_otro) return solicitudInvalida(res, 'id_usuario es obligatorio.');

        const id_conversacion = await ConversacionModel.obtenerOCrear(req.usuario.id_usuario, id_otro);
        return res.status(200).json({ ok: true, data: { id_conversacion } });
    } catch (error) {
        return manejarError(res, error, 'iniciarConversacion');
    }
};

// GET /api/conversaciones/no-leidos
const contarMensajesNoLeidos = async (req, res) => {
    try {
        const total = await ConversacionModel.contarNoLeidos(req.usuario.id_usuario);
        return res.status(200).json({ ok: true, data: { total } });
    } catch (error) {
        return manejarError(res, error, 'contarMensajesNoLeidos');
    }
};

// GET /api/conversaciones/:id_conversacion/mensajes?despues_de=&antes_de=&limite=
//   despues_de: solo mensajes nuevos (para consultar cada pocos segundos)
//   antes_de:   historial anterior (scroll hacia arriba)
const listarMensajes = async (req, res) => {
    try {
        const id_conversacion = entero(req.params.id_conversacion);
        if (!id_conversacion) return solicitudInvalida(res, 'id_conversacion no es válido.');

        const despues_de = idOpcional(req.query.despues_de);
        const antes_de = idOpcional(req.query.antes_de);
        if (despues_de === false || antes_de === false) {
            return solicitudInvalida(res, 'despues_de y antes_de deben ser id_mensaje válidos.');
        }
        if (despues_de && antes_de) {
            return solicitudInvalida(res, 'Usa despues_de o antes_de, no ambos.');
        }

        const limite = Math.min(entero(req.query.limite) || CHAT.MENSAJES_POR_PAGINA, CHAT.MENSAJES_POR_PAGINA_MAX);

        const mensajes = await ConversacionModel.listarMensajes({
            id_usuario: req.usuario.id_usuario,
            id_conversacion,
            despues_de,
            antes_de,
            limite
        });
        return res.status(200).json({ ok: true, total: mensajes.length, data: mensajes });
    } catch (error) {
        return manejarError(res, error, 'listarMensajes');
    }
};

// POST /api/conversaciones/:id_conversacion/mensajes  { contenido?, url_imagen? }
const enviarMensaje = async (req, res) => {
    try {
        const id_conversacion = entero(req.params.id_conversacion);
        if (!id_conversacion) return solicitudInvalida(res, 'id_conversacion no es válido.');

        const body = req.body ?? {};
        if (body.contenido !== undefined && body.contenido !== null && typeof body.contenido !== 'string') {
            return solicitudInvalida(res, 'contenido debe ser texto.');
        }
        const contenido = texto(body.contenido) || null;
        const url_imagen = body.url_imagen ?? null;

        if (!contenido && !url_imagen) {
            return solicitudInvalida(res, 'El mensaje debe tener contenido o url_imagen.');
        }
        if (contenido && contenido.length > CHAT.MAX_CONTENIDO) {
            return solicitudInvalida(res, `El mensaje no puede superar los ${CHAT.MAX_CONTENIDO} caracteres.`);
        }
        if (url_imagen !== null && !esUrlImagen(url_imagen)) {
            return solicitudInvalida(res, 'url_imagen debe ser una ruta devuelta por POST /api/archivos.');
        }

        const mensaje = await ConversacionModel.enviarMensaje(
            req.usuario.id_usuario,
            id_conversacion,
            contenido,
            url_imagen
        );
        return res.status(201).json({ ok: true, mensaje: 'Mensaje enviado.', data: mensaje });
    } catch (error) {
        return manejarError(res, error, 'enviarMensaje');
    }
};

// PATCH /api/conversaciones/:id_conversacion/leida
const marcarConversacionLeida = async (req, res) => {
    try {
        const id_conversacion = entero(req.params.id_conversacion);
        if (!id_conversacion) return solicitudInvalida(res, 'id_conversacion no es válido.');

        await ConversacionModel.marcarLeida(req.usuario.id_usuario, id_conversacion);
        return res.status(200).json({ ok: true, mensaje: 'Conversación marcada como leída.' });
    } catch (error) {
        return manejarError(res, error, 'marcarConversacionLeida');
    }
};

module.exports = {
    listarConversaciones,
    iniciarConversacion,
    contarMensajesNoLeidos,
    listarMensajes,
    enviarMensaje,
    marcarConversacionLeida
};
