const db = require('../config/db');

class ServicioModel {
    static async buscarServicios(id_categoria, tipo_pago) {
        const [results] = await db.query('CALL sp_servicios_buscar(?, ?)', [id_categoria, tipo_pago || null]);
        return results[0];
    }
}

module.exports = ServicioModel;