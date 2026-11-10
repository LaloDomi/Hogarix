const db = require('../config/db');

class DispositivoModel {
    static async registrar(id_usuario, token_fcm, plataforma) {
        await db.query('CALL sp_dispositivo_registrar(?, ?, ?)', [id_usuario, token_fcm, plataforma]);
    }

    static async eliminar(id_usuario, token_fcm) {
        await db.query('CALL sp_dispositivo_eliminar(?, ?)', [id_usuario, token_fcm]);
    }
}

module.exports = DispositivoModel;
