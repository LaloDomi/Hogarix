const db = require('../config/db');

class TrabajadorModel {
    static async obtenerPerfil(id_usuario) {
        const [results] = await db.query('CALL sp_trabajador_obtener_perfil(?)', [id_usuario]);
        const perfil = results[0][0];
        return {
            ...perfil,
            disponible: Boolean(perfil.disponible),
            servicios: results[1]
        };
    }

    static async actualizarPerfil(id_usuario, biografia, disponible) {
        const [results] = await db.query(
            'CALL sp_trabajador_actualizar_perfil(?, ?, ?)',
            [id_usuario, biografia, disponible]
        );
        const perfil = results[0][0];
        return { ...perfil, disponible: Boolean(perfil.disponible) };
    }

    static async crearServicio(id_usuario, { id_categoria, tipo_pago, precio_base, descripcion_servicio }) {
        const [results] = await db.query(
            'CALL sp_servicio_crear(?, ?, ?, ?, ?)',
            [id_usuario, id_categoria, tipo_pago, precio_base, descripcion_servicio]
        );
        return results[0][0].id_servicio;
    }

    static async actualizarServicio(id_usuario, id_servicio, { id_categoria, tipo_pago, precio_base, descripcion_servicio }) {
        await db.query(
            'CALL sp_servicio_actualizar(?, ?, ?, ?, ?, ?)',
            [id_usuario, id_servicio, id_categoria, tipo_pago, precio_base, descripcion_servicio]
        );
    }

    static async eliminarServicio(id_usuario, id_servicio) {
        await db.query('CALL sp_servicio_eliminar(?, ?)', [id_usuario, id_servicio]);
    }
}

module.exports = TrabajadorModel;
