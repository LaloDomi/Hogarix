const db = require('../config/db');

// MySQL devuelve las comparaciones (a = b) como 0/1.
const normalizarMensaje = (fila) => ({
    ...fila,
    es_mio: Boolean(fila.es_mio),
    leido: Boolean(fila.leido)
});

const normalizarConversacion = (fila) => ({
    ...fila,
    ultimo_es_mio: Boolean(fila.ultimo_es_mio),
    no_leidos: Number(fila.no_leidos)
});

class ConversacionModel {
    static async obtenerOCrear(id_usuario, id_otro) {
        const [results] = await db.query('CALL sp_conversacion_obtener_o_crear(?, ?)', [id_usuario, id_otro]);
        return results[0][0].id_conversacion;
    }

    static async listar(id_usuario, limite, offset) {
        const [results] = await db.query('CALL sp_conversaciones_listar(?, ?, ?)', [id_usuario, limite, offset]);
        return results[0].map(normalizarConversacion);
    }

    static async listarMensajes({ id_usuario, id_conversacion, despues_de = null, antes_de = null, limite }) {
        const [results] = await db.query(
            'CALL sp_mensajes_listar(?, ?, ?, ?, ?)',
            [id_usuario, id_conversacion, despues_de, antes_de, limite]
        );
        return results[0].map(normalizarMensaje);
    }

    static async enviarMensaje(id_usuario, id_conversacion, contenido, url_imagen) {
        const [results] = await db.query(
            'CALL sp_mensaje_enviar(?, ?, ?, ?)',
            [id_usuario, id_conversacion, contenido, url_imagen]
        );
        return normalizarMensaje(results[0][0]);
    }

    static async marcarLeida(id_usuario, id_conversacion) {
        await db.query('CALL sp_conversacion_marcar_leida(?, ?)', [id_usuario, id_conversacion]);
    }

    static async contarNoLeidos(id_usuario) {
        const [results] = await db.query('CALL sp_mensajes_contar_no_leidos(?)', [id_usuario]);
        return Number(results[0][0].total);
    }
}

module.exports = ConversacionModel;
