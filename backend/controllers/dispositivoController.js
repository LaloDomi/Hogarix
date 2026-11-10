const DispositivoModel = require('../models/dispositivoModel');
const { PLATAFORMAS } = require('../config/constantes');
const { manejarError, solicitudInvalida } = require('../utils/helpers');

const registrarDispositivo = async (req, res) => {
    try {
        const { token_fcm, plataforma } = req.body ?? {};

        if (typeof token_fcm !== 'string' || !token_fcm.trim() || token_fcm.length > 255) {
            return solicitudInvalida(res, 'token_fcm es obligatorio y no puede superar los 255 caracteres.');
        }
        if (!PLATAFORMAS.includes(plataforma)) {
            return solicitudInvalida(res, `plataforma debe ser una de: ${PLATAFORMAS.join(', ')}.`);
        }

        await DispositivoModel.registrar(req.usuario.id_usuario, token_fcm.trim(), plataforma);
        return res.status(200).json({ ok: true, mensaje: 'Dispositivo registrado.' });
    } catch (error) {
        return manejarError(res, error, 'registrarDispositivo');
    }
};

const eliminarDispositivo = async (req, res) => {
    try {
        const { token_fcm } = req.body ?? {};

        if (typeof token_fcm !== 'string' || !token_fcm.trim() || token_fcm.length > 255) {
            return solicitudInvalida(res, 'token_fcm es obligatorio.');
        }

        await DispositivoModel.eliminar(req.usuario.id_usuario, token_fcm.trim());
        return res.status(200).json({ ok: true, mensaje: 'Dispositivo eliminado.' });
    } catch (error) {
        return manejarError(res, error, 'eliminarDispositivo');
    }
};

module.exports = { registrarDispositivo, eliminarDispositivo };
