const CategoriaModel = require('../models/categoriaModel');
const { manejarError } = require('../utils/helpers');

const listarCategorias = async (req, res) => {
    try {
        const categorias = await CategoriaModel.listar();
        return res.status(200).json({ ok: true, total: categorias.length, data: categorias });
    } catch (error) {
        return manejarError(res, error, 'listarCategorias');
    }
};

module.exports = { listarCategorias };
