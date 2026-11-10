const ServicioModel = require('../models/servicioModel');


const obtenerServiciosPorFiltro = async (req, res) => {
    try {
        const { id_categoria, tipo_pago } = req.query;

        if(!id_categoria) {
            return res.status(400).json({
                ok: false,
                mensaje: 'El parámetro id_categoria es obligatorio'
            });
        }

        const servicios = await ServicioModel.buscarServicios(id_categoria, tipo_pago);

        return res.status(200).json({
            ok: true,
            total: servicios.length,
            data: servicios
        });
    } catch (error) {
        console.error(error);
        return res.status(500).json({
            ok: false,
            mensaje: 'Error interno del servidor'
        });
    }
};

module.exports = {
    obtenerServiciosPorFiltro
};