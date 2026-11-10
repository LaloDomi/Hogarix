const db = require('../config/db');

// MySQL devuelve JSON nativo ya parseado; MariaDB lo devuelve como texto.
const normalizar = (fila) => ({
    ...fila,
    me_gusta: Boolean(fila.me_gusta),
    imagenes: typeof fila.imagenes === 'string' ? JSON.parse(fila.imagenes) : fila.imagenes
});

class PublicacionModel {
    static async listar({ id_usuario_actual, id_autor = null, id_publicacion = null, limite, offset }) {
        const [results] = await db.query(
            'CALL sp_publicaciones_listar(?, ?, ?, ?, ?)',
            [id_usuario_actual, id_autor, id_publicacion, limite, offset]
        );
        return results[0].map(normalizar);
    }

    // La publicación y sus imágenes se guardan en una sola transacción.
    static async crear(id_usuario, titulo, contenido, imagenes) {
        const connection = await db.getConnection();
        try {
            await connection.beginTransaction();

            const [results] = await connection.query(
                'CALL sp_publicacion_crear(?, ?, ?)',
                [id_usuario, titulo, contenido]
            );
            const id_publicacion = results[0][0].id_publicacion;

            for (const url of imagenes) {
                await connection.query('CALL sp_publicacion_agregar_imagen(?, ?)', [id_publicacion, url]);
            }

            await connection.commit();
            return id_publicacion;
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    static async eliminar(id_usuario, id_publicacion) {
        await db.query('CALL sp_publicacion_eliminar(?, ?)', [id_usuario, id_publicacion]);
    }

    static async listarComentarios({ id_publicacion, id_usuario_actual, limite, offset }) {
        const [results] = await db.query(
            'CALL sp_comentarios_listar(?, ?, ?, ?)',
            [id_publicacion, id_usuario_actual, limite, offset]
        );
        return results[0];
    }

    static async crearComentario(id_usuario, id_publicacion, contenido) {
        const [results] = await db.query(
            'CALL sp_comentario_crear(?, ?, ?)',
            [id_usuario, id_publicacion, contenido]
        );
        return results[0][0].id_comentario;
    }

    static async eliminarComentario(id_usuario, id_publicacion, id_comentario) {
        await db.query('CALL sp_comentario_eliminar(?, ?, ?)', [id_usuario, id_publicacion, id_comentario]);
    }

    static async agregarLike(id_usuario, id_publicacion) {
        const [results] = await db.query('CALL sp_like_agregar(?, ?)', [id_usuario, id_publicacion]);
        return results[0][0].total_likes;
    }

    static async quitarLike(id_usuario, id_publicacion) {
        const [results] = await db.query('CALL sp_like_quitar(?, ?)', [id_usuario, id_publicacion]);
        return results[0][0].total_likes;
    }
}

module.exports = PublicacionModel;
