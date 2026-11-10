const db = require('../config/db');

// Igual que la agenda: las horas se devuelven como texto 'YYYY-MM-DD HH:mm:ss'
// (hora de pared), sin convertirlas a UTC.
const comoTexto = (campo, siguiente) =>
    campo.type === 'DATETIME' ? campo.string() : siguiente();

const normalizar = (fila) => ({ ...fila, propuesta_por_mi: Boolean(fila.propuesta_por_mi) });

class VisitaModel {
    static async crear(id_usuario, { id_solicitud, fecha_inicio, fecha_fin, direccion, notas }) {
        const [results] = await db.query(
            'CALL sp_visita_crear(?, ?, ?, ?, ?, ?)',
            [id_usuario, id_solicitud, fecha_inicio, fecha_fin, direccion, notas]
        );
        return results[0][0];
    }

    static async listar(id_usuario, desde, hasta) {
        const [results] = await db.query({
            sql: 'CALL sp_visitas_listar(?, ?, ?)',
            values: [id_usuario, desde, hasta],
            typeCast: comoTexto
        });
        return results[0].map(normalizar);
    }

    static async cambiarEstado(id_usuario, id_visita, estado) {
        const [results] = await db.query('CALL sp_visita_cambiar_estado(?, ?, ?)', [id_usuario, id_visita, estado]);
        return results[0][0];
    }

    static async reprogramar(id_usuario, id_visita, { fecha_inicio, fecha_fin, direccion, notas }) {
        const [results] = await db.query(
            'CALL sp_visita_reprogramar(?, ?, ?, ?, ?, ?)',
            [id_usuario, id_visita, fecha_inicio, fecha_fin, direccion, notas]
        );
        return results[0][0];
    }
}

module.exports = VisitaModel;
