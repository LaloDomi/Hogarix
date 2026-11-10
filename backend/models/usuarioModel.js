const db = require('../config/db');

// Fechas como texto ('YYYY-MM-DD'): así la fecha de nacimiento no se recorre
// un día al convertirse a UTC.
const fechasComoTexto = (campo, siguiente) =>
    campo.type === 'DATE' || campo.type === 'DATETIME' ? campo.string() : siguiente();

class UsuarioModel {
    // Buscar usuario por correo para validación de login / registro
    static async buscarPorCorreo(correo) {
        const [results] = await db.query('CALL sp_usuario_buscar_por_correo(?)', [correo]);
        return results[0][0];
    }

    // Registrar un nuevo usuario (y su perfil de trabajador si aplica) vía procedimiento almacenado
    static async crearUsuario({ id_rol, nombre, apellido, correo, contrasena, telefono }) {
        const connection = await db.getConnection();
        try {
            await connection.query(
                'CALL sp_usuario_crear(?, ?, ?, ?, ?, ?, @id_usuario)',
                [id_rol, nombre, apellido, correo, contrasena, telefono || null]
            );
            const [[fila]] = await connection.query('SELECT @id_usuario AS id_usuario');
            return fila.id_usuario;
        } finally {
            connection.release();
        }
    }

    // Obtener datos del perfil del usuario autenticado
    static async obtenerPorId(id_usuario) {
        const [results] = await db.query({
            sql: 'CALL sp_usuario_obtener_por_id(?)',
            values: [id_usuario],
            typeCast: fechasComoTexto
        });
        return results[0][0];
    }

    // Actualiza datos del perfil. Los campos undefined/null no cambian.
    static async actualizarPerfil(id_usuario, d) {
        const [results] = await db.query({
            sql: 'CALL sp_usuario_actualizar_perfil(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            typeCast: fechasComoTexto,
            values: [
                id_usuario,
                d.nombre ?? null,
                d.apellido ?? null,
                d.telefono ?? null,
                d.foto_perfil ?? null,
                d.estado_mx ?? null,
                d.municipio ?? null,
                d.colonia ?? null,
                d.fecha_nacimiento ?? null,
                d.sexo ?? null
            ]
        });
        return results[0][0];
    }

    // Busca por id de Google/Facebook o por correo (y lo vincula).
    static async buscarSocial(proveedor, id_externo, correo) {
        const [results] = await db.query('CALL sp_usuario_buscar_social(?, ?, ?)', [
            proveedor,
            id_externo,
            correo || null
        ]);
        return results[0][0];
    }

    static async vincularSocial(id_usuario, proveedor, id_externo) {
        await db.query('CALL sp_usuario_vincular_social(?, ?, ?)', [id_usuario, proveedor, id_externo]);
    }

    // telefono: 10 dígitos ya normalizados (ver normalizarTelefono en helpers).
    static async buscarPorTelefono(telefono) {
        const [results] = await db.query('CALL sp_usuario_buscar_por_telefono(?)', [telefono]);
        return results[0][0];
    }

    static async obtenerHashContrasena(id_usuario) {
        const [results] = await db.query('CALL sp_usuario_obtener_contrasena(?)', [id_usuario]);
        return results[0][0]?.contrasena ?? null;
    }

    static async cambiarContrasena(id_usuario, contrasenaHash) {
        await db.query('CALL sp_usuario_cambiar_contrasena(?, ?)', [id_usuario, contrasenaHash]);
    }

    static async cambiarCorreo(id_usuario, correo) {
        const [results] = await db.query({
            sql: 'CALL sp_usuario_cambiar_correo(?, ?)',
            values: [id_usuario, correo],
            typeCast: fechasComoTexto
        });
        return results[0][0];
    }

    // ---- Códigos enviados por correo (migración 004) ----
    static async crearCodigo(destino, proposito, codigoHash, minutos) {
        await db.query('CALL sp_codigo_crear(?, ?, ?, ?)', [destino, proposito, codigoHash, minutos]);
    }

    static async obtenerCodigoVigente(destino, proposito) {
        const [results] = await db.query('CALL sp_codigo_obtener_vigente(?, ?)', [destino, proposito]);
        return results[0][0];
    }

    static async registrarIntentoCodigo(id_codigo) {
        await db.query('CALL sp_codigo_registrar_intento(?)', [id_codigo]);
    }

    static async marcarCodigoUsado(id_codigo) {
        await db.query('CALL sp_codigo_marcar_usado(?)', [id_codigo]);
    }
}

module.exports = UsuarioModel;