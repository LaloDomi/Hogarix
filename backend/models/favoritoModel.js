const db = require('../config/db');

class FavoritoModel {
    static async agregar(id_cliente, id_trabajador) {
        await db.query('CALL sp_favorito_agregar(?, ?)', [id_cliente, id_trabajador]);
    }

    static async quitar(id_cliente, id_trabajador) {
        await db.query('CALL sp_favorito_quitar(?, ?)', [id_cliente, id_trabajador]);
    }

    static async listar(id_cliente) {
        const [results] = await db.query('CALL sp_favoritos_listar(?)', [id_cliente]);
        return results[0].map((fila) => ({ ...fila, disponible: Boolean(fila.disponible) }));
    }
}

module.exports = FavoritoModel;
