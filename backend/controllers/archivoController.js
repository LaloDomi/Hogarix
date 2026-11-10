const fs = require('fs/promises');
const path = require('path');
const { randomUUID } = require('crypto');
const multer = require('multer');
const ArchivoModel = require('../models/archivoModel');
const {
    UPLOADS_DIR,
    RUTA_PUBLICA,
    MAX_BYTES_IMAGEN,
    detectarTipoImagen,
    subirImagen
} = require('../config/almacenamiento');
const { urlAbsoluta, manejarError, solicitudInvalida } = require('../utils/helpers');

// Ejecuta multer y convierte sus errores en respuestas { ok: false, mensaje }.
const recibirArchivo = (req, res) =>
    new Promise((resolve) => {
        subirImagen(req, res, (err) => {
            if (!err) return resolve(true);
            if (err instanceof multer.MulterError) {
                if (err.code === 'LIMIT_FILE_SIZE') {
                    res.status(413).json({
                        ok: false,
                        mensaje: `La imagen no puede pesar más de ${MAX_BYTES_IMAGEN / (1024 * 1024)} MB.`
                    });
                } else {
                    solicitudInvalida(res, 'Envía una sola imagen en el campo "archivo" (multipart/form-data).');
                }
            } else {
                manejarError(res, err, 'subirImagen.multer');
            }
            resolve(false);
        });
    });

// POST /api/archivos  (multipart/form-data, campo "archivo")
// Devuelve la ruta relativa que se guarda en la base y la URL completa.
const subirArchivo = async (req, res) => {
    if (!(await recibirArchivo(req, res))) return;

    if (!req.file) {
        return solicitudInvalida(res, 'Envía la imagen en el campo "archivo" (multipart/form-data).');
    }

    const tipo = detectarTipoImagen(req.file.buffer);
    if (!tipo) {
        return res.status(415).json({ ok: false, mensaje: 'Solo se permiten imágenes JPG, PNG o WEBP.' });
    }

    const ahora = new Date();
    const anio = String(ahora.getFullYear());
    const mes = String(ahora.getMonth() + 1).padStart(2, '0');
    const nombre = `${randomUUID()}.${tipo.extension}`;
    const carpeta = path.join(UPLOADS_DIR, 'imagenes', anio, mes);
    const rutaDisco = path.join(carpeta, nombre);
    const ruta = `${RUTA_PUBLICA}/imagenes/${anio}/${mes}/${nombre}`;

    try {
        await fs.mkdir(carpeta, { recursive: true });
        await fs.writeFile(rutaDisco, req.file.buffer, { flag: 'wx' });

        const id_archivo = await ArchivoModel.registrar(req.usuario.id_usuario, ruta, tipo.mime, req.file.size);

        return res.status(201).json({
            ok: true,
            mensaje: 'Imagen subida.',
            data: {
                id_archivo,
                ruta,
                url: urlAbsoluta(req, ruta),
                tipo_mime: tipo.mime,
                tamano_bytes: req.file.size
            }
        });
    } catch (error) {
        await fs.unlink(rutaDisco).catch(() => {});
        return manejarError(res, error, 'subirArchivo');
    }
};

module.exports = { subirArchivo };
