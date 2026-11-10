const db = require('../config/db');

class ModeracionModel {
    static async crearReporte(id_usuario_reporta, { id_usuario_reportado, id_publicacion, motivo, detalle }) {
        const [results] = await db.query(
            'CALL sp_reporte_crear(?, ?, ?, ?, ?)',
            [id_usuario_reporta, id_usuario_reportado, id_publicacion, motivo, detalle]
        );
        return results[0][0].id_reporte;
    }

    static async bloquear(id_usuario, id_bloqueado) {
        await db.query('CALL sp_bloqueo_agregar(?, ?)', [id_usuario, id_bloqueado]);
    }

    static async desbloquear(id_usuario, id_bloqueado) {
        await db.query('CALL sp_bloqueo_quitar(?, ?)', [id_usuario, id_bloqueado]);
    }

    static async listarBloqueos(id_usuario) {
        const [results] = await db.query('CALL sp_bloqueos_listar(?)', [id_usuario]);
        return results[0];
    }
}

module.exports = ModeracionModel;
