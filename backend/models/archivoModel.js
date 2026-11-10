const db = require('../config/db');

class ArchivoModel {
    static async registrar(id_usuario, ruta, tipo_mime, tamano_bytes) {
        const [results] = await db.query(
            'CALL sp_archivo_registrar(?, ?, ?, ?)',
            [id_usuario, ruta, tipo_mime, tamano_bytes]
        );
        return results[0][0].id_archivo;
    }
}

module.exports = ArchivoModel;
