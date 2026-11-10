const db = require('../config/db');

class AgendaModel {
    static async crear(id_usuario, { titulo, descripcion, fecha_inicio, fecha_fin }) {
        const [results] = await db.query(
            'CALL sp_evento_crear(?, ?, ?, ?, ?)',
            [id_usuario, titulo, descripcion, fecha_inicio, fecha_fin]
        );
        return results[0][0].id_evento;
    }

    static async listar(id_usuario, desde, hasta) {
        const [results] = await db.query('CALL sp_evento_listar(?, ?, ?)', [id_usuario, desde, hasta]);
        return results[0];
    }

    static async actualizar(id_usuario, id_evento, { titulo, descripcion, fecha_inicio, fecha_fin }) {
        await db.query(
            'CALL sp_evento_actualizar(?, ?, ?, ?, ?, ?)',
            [id_usuario, id_evento, titulo, descripcion, fecha_inicio, fecha_fin]
        );
    }

    static async eliminar(id_usuario, id_evento) {
        await db.query('CALL sp_evento_eliminar(?, ?)', [id_usuario, id_evento]);
    }
}

module.exports = AgendaModel;
