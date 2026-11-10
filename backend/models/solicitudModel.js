const db = require('../config/db');

const normalizar = (fila) => ({ ...fila, ya_califique: Boolean(fila.ya_califique) });

class SolicitudModel {
    static async crear(id_cliente, { id_trabajador, id_categoria, tipo_pago_acordado, monto_estimado }) {
        const [results] = await db.query(
            'CALL sp_solicitud_crear(?, ?, ?, ?, ?)',
            [id_cliente, id_trabajador, id_categoria, tipo_pago_acordado, monto_estimado]
        );
        return results[0][0].id_solicitud;
    }

    static async listar({ id_usuario, id_solicitud = null, estado = null, limite, offset }) {
        const [results] = await db.query(
            'CALL sp_solicitud_listar(?, ?, ?, ?, ?)',
            [id_usuario, id_solicitud, estado, limite, offset]
        );
        return results[0].map(normalizar);
    }

    static async cambiarEstado(id_usuario, id_solicitud, nuevo_estado) {
        const [results] = await db.query(
            'CALL sp_solicitud_cambiar_estado(?, ?, ?)',
            [id_usuario, id_solicitud, nuevo_estado]
        );
        return results[0][0];
    }
}

module.exports = SolicitudModel;
