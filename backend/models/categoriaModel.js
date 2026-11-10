const db = require('../config/db');

class CategoriaModel {
    static async listar() {
        const [results] = await db.query('CALL sp_categorias_listar()');
        return results[0];
    }
}

module.exports = CategoriaModel;
