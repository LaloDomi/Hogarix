const db = require('../config/db');

const normalizar = (fila) => ({ ...fila, leida: Boolean(fila.leida) });

class NotificacionModel {
    static async crear(id_usuario, { tipo, titulo, cuerpo = null, id_referencia = null }) {
        const [results] = await db.query(
            'CALL sp_notificacion_crear(?, ?, ?, ?, ?)',
            [id_usuario, tipo, titulo, cuerpo, id_referencia]
        );
        return results[0][0].id_notificacion;
    }

    static async listar(id_usuario, solo_no_leidas, limite, offset) {
        const [results] = await db.query(
            'CALL sp_notificaciones_listar(?, ?, ?, ?)',
            [id_usuario, solo_no_leidas, limite, offset]
        );
        return results[0].map(normalizar);
    }

    static async contarNoLeidas(id_usuario) {
        const [results] = await db.query('CALL sp_notificaciones_contar_no_leidas(?)', [id_usuario]);
        return Number(results[0][0].total);
    }

    static async marcarLeida(id_usuario, id_notificacion) {
        await db.query('CALL sp_notificacion_marcar_leida(?, ?)', [id_usuario, id_notificacion]);
    }

    static async marcarTodasLeidas(id_usuario) {
        const [results] = await db.query('CALL sp_notificaciones_marcar_todas_leidas(?)', [id_usuario]);
        return Number(results[0][0].actualizadas);
    }
}

module.exports = NotificacionModel;
