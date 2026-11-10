const db = require('../config/db');

class ResenaModel {
    static async crear(id_autor, id_solicitud, calificacion, comentario) {
        const [results] = await db.query(
            'CALL sp_resena_crear(?, ?, ?, ?)',
            [id_autor, id_solicitud, calificacion, comentario]
        );
        return results[0][0].id_resena;
    }

    static async listarPorUsuario(id_usuario, limite, offset) {
        const [results] = await db.query(
            'CALL sp_resenas_listar_usuario(?, ?, ?)',
            [id_usuario, limite, offset]
        );
        return results[0];
    }
}

module.exports = ResenaModel;
