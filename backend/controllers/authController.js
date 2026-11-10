const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const UsuarioModel = require('../models/usuarioModel');
const { ROLES } = require('../config/constantes');
const { esUrlImagen, esUrlHttps, texto, manejarError, CORREO_VALIDO, normalizarTelefono } = require('../utils/helpers');
const { enviarCodigo, correoConfigurado, ErrorCorreo } = require('../utils/correo');
const { verificarGoogle, verificarFacebook, ErrorSocial } = require('../utils/proveedoresSociales');

const firmarToken = (id_usuario, id_rol) =>
    jwt.sign({ id_usuario, id_rol }, process.env.JWT_SECRET, { expiresIn: '30d' });

// Estados de la República (para validar la ubicación elegida a mano).
const ESTADOS_MX = [
    'Aguascalientes', 'Baja California', 'Baja California Sur', 'Campeche', 'Chiapas',
    'Chihuahua', 'Ciudad de México', 'Coahuila', 'Colima', 'Durango', 'Estado de México',
    'Guanajuato', 'Guerrero', 'Hidalgo', 'Jalisco', 'Michoacán', 'Morelos', 'Nayarit',
    'Nuevo León', 'Oaxaca', 'Puebla', 'Querétaro', 'Quintana Roo', 'San Luis Potosí',
    'Sinaloa', 'Sonora', 'Tabasco', 'Tamaulipas', 'Tlaxcala', 'Veracruz', 'Yucatán', 'Zacatecas'
];
const SEXOS = ['Masculino', 'Femenino', 'Otro', 'Prefiero no decir'];

// Datos de la sesión que se devuelven al entrar (registro, login, código...).
const usuarioSesion = (u) => ({
    id_usuario: u.id_usuario,
    nombre: u.nombre,
    apellido: u.apellido,
    correo: u.correo || null,
    telefono: u.telefono || null,
    id_rol: Number(u.id_rol),
    rol: u.nombre_rol
});

const responderSesion = (res, status, mensaje, usuario) =>
    res.status(status).json({
        ok: true,
        mensaje,
        token: firmarToken(usuario.id_usuario, Number(usuario.id_rol)),
        usuario: usuarioSesion(usuario)
    });

const rolValido = (r) => r === ROLES.CLIENTE || r === ROLES.TRABAJADOR;

// Error de validación con su código HTTP.
class ErrorPeticion extends Error {
    constructor(mensaje, codigo = 400) {
        super(mensaje);
        this.codigo = codigo;
    }
}

// Errores de estos controladores: validación, correo, procedimientos (45XXX) o 500.
const responderError = (res, error, contexto) => {
    if (error instanceof ErrorPeticion || error instanceof ErrorCorreo) {
        return res.status(error.codigo).json({ ok: false, mensaje: error.message });
    }
    return manejarError(res, error, contexto);
};

// Registro de Usuario (Cliente o Trabajador). Se puede registrar con correo,
// con teléfono o con ambos; se pide al menos uno de los dos.
const registrar = async (req, res) => {
    try {
        const b = req.body ?? {};
        const id_rol = Number(b.id_rol);
        const nombre = texto(b.nombre).slice(0, 100);
        const apellido = texto(b.apellido).slice(0, 100);
        const correo = texto(b.correo).toLowerCase() || null;
        const telefonoTexto = texto(b.telefono);
        const contrasena = typeof b.contrasena === 'string' ? b.contrasena : '';

        if (!rolValido(id_rol)) throw new ErrorPeticion('Elige si eres cliente o trabajador.');
        if (!nombre || !apellido) throw new ErrorPeticion('Ingresa tu nombre y apellido.');
        if (!correo && !telefonoTexto) throw new ErrorPeticion('Ingresa tu correo o tu número de teléfono.');
        if (correo && (!CORREO_VALIDO.test(correo) || correo.length > 150)) {
            throw new ErrorPeticion('Ingresa un correo válido.');
        }
        let telefono = null;
        if (telefonoTexto) {
            telefono = normalizarTelefono(telefonoTexto);
            if (!telefono) throw new ErrorPeticion('El teléfono debe tener 10 dígitos.');
        }
        if (contrasena.length < 6) throw new ErrorPeticion('La contraseña debe tener al menos 6 caracteres.');

        if (correo && await UsuarioModel.buscarPorCorreo(correo)) {
            throw new ErrorPeticion('El correo electrónico ya está registrado.');
        }
        if (telefono && await UsuarioModel.buscarPorTelefono(telefono)) {
            throw new ErrorPeticion('Este número de teléfono ya está registrado. Inicia sesión con él.');
        }

        // Verificación del correo: si el servidor puede mandar correos, primero
        // se envía un código y la app lo pide; con el código se crea la cuenta.
        let id_codigo = null;
        if (correo && correoConfigurado()) {
            if (b.codigo === undefined || b.codigo === null || b.codigo === '') {
                await mandarCodigo(correo, 'acceso', 'registro');
                return res.status(202).json({
                    ok: true,
                    requiere_codigo: true,
                    mensaje: `Te enviamos un código a ${correo} para confirmar tu correo.`,
                    minutos: MINUTOS_CODIGO
                });
            }
            id_codigo = await validarCodigo(correo, 'acceso', b.codigo);
        }

        const contrasenaHash = await bcrypt.hash(contrasena, 10);
        const id_usuario = await UsuarioModel.crearUsuario({
            id_rol, nombre, apellido, correo, contrasena: contrasenaHash, telefono
        });
        if (id_codigo) await UsuarioModel.marcarCodigoUsado(id_codigo);

        return responderSesion(res, 201, 'Usuario registrado exitosamente.', {
            id_usuario, id_rol, nombre, apellido, correo, telefono
        });
    } catch (error) {
        return responderError(res, error, 'registrar');
    }
};

// Login con correo o con teléfono + contraseña.
// Acepta { identificador } o, por compatibilidad, { correo } / { telefono }.
const login = async (req, res) => {
    try {
        const b = req.body ?? {};
        const identificador = texto(b.identificador || b.correo || b.telefono);
        const contrasena = typeof b.contrasena === 'string' ? b.contrasena : '';

        if (!identificador || !contrasena) {
            throw new ErrorPeticion('Ingresa tu correo o teléfono y tu contraseña.');
        }

        let usuario = null;
        if (identificador.includes('@')) {
            usuario = await UsuarioModel.buscarPorCorreo(identificador.toLowerCase());
        } else {
            const telefono = normalizarTelefono(identificador);
            if (telefono) usuario = await UsuarioModel.buscarPorTelefono(telefono);
        }

        const valida = usuario && await bcrypt.compare(contrasena, usuario.contrasena);
        if (!valida) throw new ErrorPeticion('Credenciales inválidas.', 401);
        if (usuario.activo !== undefined && usuario.activo !== null && !Number(usuario.activo)) {
            throw new ErrorPeticion('Esta cuenta está desactivada.', 403);
        }

        return responderSesion(res, 200, 'Inicio de sesión exitoso.', usuario);
    } catch (error) {
        return responderError(res, error, 'login');
    }
};

// ---------------------------------------------------------------------
// Códigos de 6 dígitos por correo: restablecer contraseña y entrar sin
// contraseña ("Continuar con Gmail"). No necesitan Google Cloud.
// ---------------------------------------------------------------------
const MINUTOS_CODIGO = 15;
const MAX_INTENTOS = 5;
const PROPOSITOS = ['restablecer', 'acceso'];

const hashCodigo = (destino, codigo) =>
    crypto.createHmac('sha256', process.env.JWT_SECRET).update(`${destino}:${codigo}`).digest('hex');

const correoDe = (valor) => {
    const correo = texto(valor).toLowerCase();
    if (!CORREO_VALIDO.test(correo) || correo.length > 150) throw new ErrorPeticion('Ingresa un correo válido.');
    return correo;
};

// Revisa el código. Si es incorrecto suma un intento. Devuelve el id del código.
const validarCodigo = async (destino, proposito, valor) => {
    const codigo = texto(valor);
    if (!/^\d{6}$/.test(codigo)) throw new ErrorPeticion('El código debe tener 6 dígitos.');

    const fila = await UsuarioModel.obtenerCodigoVigente(destino, proposito);
    if (!fila || Number(fila.intentos) >= MAX_INTENTOS) {
        throw new ErrorPeticion('El código venció o ya no es válido. Pide uno nuevo.');
    }

    const esperado = Buffer.from(fila.codigo_hash, 'hex');
    const recibido = Buffer.from(hashCodigo(destino, codigo), 'hex');
    if (esperado.length !== recibido.length || !crypto.timingSafeEqual(esperado, recibido)) {
        await UsuarioModel.registrarIntentoCodigo(fila.id_codigo);
        const quedan = MAX_INTENTOS - Number(fila.intentos) - 1;
        throw new ErrorPeticion(quedan > 0
            ? `Código incorrecto. Te quedan ${quedan} ${quedan === 1 ? 'intento' : 'intentos'}.`
            : 'Código incorrecto. Pide uno nuevo.');
    }
    return fila.id_codigo;
};

// Crea el código, lo guarda (hash) y lo manda. [plantilla] elige el texto del correo.
const mandarCodigo = async (correo, proposito, plantilla = proposito) => {
    const codigo = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
    await UsuarioModel.crearCodigo(correo, proposito, hashCodigo(correo, codigo), MINUTOS_CODIGO);
    await enviarCodigo({ para: correo, codigo, proposito: plantilla, minutos: MINUTOS_CODIGO });
};

// POST /api/auth/codigo  { correo, proposito: 'restablecer' | 'acceso' }
const enviarCodigoCorreo = async (req, res) => {
    try {
        const b = req.body ?? {};
        const proposito = texto(b.proposito);
        if (!PROPOSITOS.includes(proposito)) throw new ErrorPeticion('proposito debe ser restablecer o acceso.');
        const correo = correoDe(b.correo);

        if (proposito === 'restablecer' && !(await UsuarioModel.buscarPorCorreo(correo))) {
            throw new ErrorPeticion('No hay ninguna cuenta con ese correo.', 404);
        }

        await mandarCodigo(correo, proposito);

        return res.status(200).json({
            ok: true,
            mensaje: `Te enviamos un código a ${correo}. Revisa también la carpeta de spam.`,
            minutos: MINUTOS_CODIGO
        });
    } catch (error) {
        return responderError(res, error, 'enviarCodigoCorreo');
    }
};

// POST /api/auth/contrasena/restablecer  { correo, codigo, contrasena }
// Si el código es correcto cambia la contraseña y deja la sesión iniciada.
const restablecerContrasena = async (req, res) => {
    try {
        const b = req.body ?? {};
        const correo = correoDe(b.correo);
        const contrasena = typeof b.contrasena === 'string' ? b.contrasena : '';
        if (contrasena.length < 6) throw new ErrorPeticion('La contraseña debe tener al menos 6 caracteres.');

        const usuario = await UsuarioModel.buscarPorCorreo(correo);
        if (!usuario) throw new ErrorPeticion('No hay ninguna cuenta con ese correo.', 404);

        const id_codigo = await validarCodigo(correo, 'restablecer', b.codigo);
        await UsuarioModel.cambiarContrasena(usuario.id_usuario, await bcrypt.hash(contrasena, 10));
        await UsuarioModel.marcarCodigoUsado(id_codigo);

        return responderSesion(res, 200, 'Contraseña actualizada.', usuario);
    } catch (error) {
        return responderError(res, error, 'restablecerContrasena');
    }
};

// POST /api/auth/codigo/verificar  { correo, codigo, id_rol?, nombre?, apellido? }
// Entrar con el código del correo. Si el correo no tiene cuenta y faltan los
// datos, responde { requiere_registro: true } sin gastar el código, para que la
// app pida rol, nombre y apellido y vuelva a llamar.
const accederConCodigo = async (req, res) => {
    try {
        const b = req.body ?? {};
        const correo = correoDe(b.correo);
        const id_codigo = await validarCodigo(correo, 'acceso', b.codigo);

        let usuario = await UsuarioModel.buscarPorCorreo(correo);
        let creado = false;

        if (!usuario) {
            const id_rol = Number(b.id_rol);
            const nombre = texto(b.nombre).slice(0, 100);
            const apellido = texto(b.apellido).slice(0, 100);
            if (!rolValido(id_rol) || !nombre || !apellido) {
                return res.status(200).json({ ok: true, requiere_registro: true, correo });
            }
            // Sin contraseña: se guarda un hash aleatorio. Si después quiere una,
            // usa "¿Olvidaste tu contraseña?".
            const contrasena = await bcrypt.hash(crypto.randomBytes(32).toString('hex'), 10);
            const id_usuario = await UsuarioModel.crearUsuario({
                id_rol, nombre, apellido, correo, contrasena, telefono: null
            });
            usuario = { id_usuario, id_rol, nombre, apellido, correo };
            creado = true;
        }

        await UsuarioModel.marcarCodigoUsado(id_codigo);
        return responderSesion(res, creado ? 201 : 200,
            creado ? 'Cuenta creada.' : 'Inicio de sesión exitoso.', usuario);
    } catch (error) {
        return responderError(res, error, 'accederConCodigo');
    }
};

// PUT /api/auth/contrasena  { actual, nueva }  (con sesión)
const cambiarContrasena = async (req, res) => {
    try {
        const b = req.body ?? {};
        const actual = typeof b.actual === 'string' ? b.actual : '';
        const nueva = typeof b.nueva === 'string' ? b.nueva : '';
        if (!actual) throw new ErrorPeticion('Escribe tu contraseña actual.');
        if (nueva.length < 6) throw new ErrorPeticion('La contraseña nueva debe tener al menos 6 caracteres.');
        if (nueva === actual) throw new ErrorPeticion('La contraseña nueva debe ser distinta a la actual.');

        const hash = await UsuarioModel.obtenerHashContrasena(req.usuario.id_usuario);
        if (!hash) throw new ErrorPeticion('Usuario no encontrado.', 404);
        if (!(await bcrypt.compare(actual, hash))) {
            // 400 y no 401: en la app un 401 cierra la sesión.
            throw new ErrorPeticion('La contraseña actual no es correcta.');
        }

        await UsuarioModel.cambiarContrasena(req.usuario.id_usuario, await bcrypt.hash(nueva, 10));
        return res.status(200).json({ ok: true, mensaje: 'Contraseña actualizada.' });
    } catch (error) {
        return responderError(res, error, 'cambiarContrasena');
    }
};

// PUT /api/auth/correo  { correo, codigo }  (con sesión)
// Agrega o cambia el correo de la cuenta. Antes se pide un código con
// POST /api/auth/codigo { correo, proposito: 'acceso' } para comprobar que es suyo.
const cambiarCorreo = async (req, res) => {
    try {
        const b = req.body ?? {};
        const correo = correoDe(b.correo);
        const id_codigo = await validarCodigo(correo, 'acceso', b.codigo);
        const usuario = await UsuarioModel.cambiarCorreo(req.usuario.id_usuario, correo);
        await UsuarioModel.marcarCodigoUsado(id_codigo);
        return res.status(200).json({ ok: true, mensaje: 'Correo guardado.', usuario });
    } catch (error) {
        return responderError(res, error, 'cambiarCorreo');
    }
};

// Obtener perfil del usuario autenticado
const obtenerPerfil = async (req, res) => {
    try {
        const id_usuario = req.usuario.id_usuario;
        const usuario = await UsuarioModel.obtenerPorId(id_usuario);

        if (!usuario) {
            return res.status(404).json({
                ok: false,
                mensaje: 'Usuario no encontrado.'
            });
        }

        return res.status(200).json({
            ok: true,
            usuario
        });
    } catch (error) {
        console.error('Error en obtenerPerfil:', error);
        return res.status(500).json({
            ok: false,
            mensaje: 'Error interno del servidor.'
        });
    }
};

// PUT /api/auth/perfil — datos personales, foto y ubicación.
// Solo se cambian los campos que vienen; '' borra un dato opcional.
const actualizarPerfil = async (req, res) => {
    try {
        const b = req.body ?? {};
        const datos = {};
        const textoOpcional = (campo, max) => {
            if (b[campo] === undefined || b[campo] === null) return null;
            if (typeof b[campo] !== 'string') return `${campo} debe ser texto.`;
            const v = b[campo].trim();
            if (v.length > max) return `${campo} no puede superar los ${max} caracteres.`;
            datos[campo] = v;
            return null;
        };

        const error =
            textoOpcional('nombre', 100) ||
            textoOpcional('apellido', 100) ||
            textoOpcional('telefono', 20) ||
            textoOpcional('municipio', 100) ||
            textoOpcional('colonia', 120) ||
            textoOpcional('estado_mx', 60) ||
            textoOpcional('sexo', 20) ||
            textoOpcional('foto_perfil', 255);
        if (error) return res.status(400).json({ ok: false, mensaje: error });

        if (datos.telefono) {
            const telefono = normalizarTelefono(datos.telefono);
            if (!telefono) return res.status(400).json({ ok: false, mensaje: 'El teléfono debe tener 10 dígitos.' });
            const otro = await UsuarioModel.buscarPorTelefono(telefono);
            if (otro && Number(otro.id_usuario) !== Number(req.usuario.id_usuario)) {
                return res.status(409).json({ ok: false, mensaje: 'Ese teléfono ya está registrado en otra cuenta.' });
            }
            datos.telefono = telefono;
        } else if (datos.telefono === '') {
            // Quien entra solo con teléfono no puede quedarse sin forma de entrar.
            const actual = await UsuarioModel.obtenerPorId(req.usuario.id_usuario);
            if (actual && !actual.correo) {
                return res.status(400).json({ ok: false, mensaje: 'Tu cuenta usa el teléfono para entrar. Agrega un correo antes de quitarlo.' });
            }
        }
        if (datos.nombre === '' || datos.apellido === '') {
            return res.status(400).json({ ok: false, mensaje: 'El nombre y el apellido no pueden quedar vacíos.' });
        }
        if (datos.estado_mx && !ESTADOS_MX.includes(datos.estado_mx)) {
            return res.status(400).json({ ok: false, mensaje: 'Elige un estado de la lista.' });
        }
        if (datos.sexo && !SEXOS.includes(datos.sexo)) {
            return res.status(400).json({ ok: false, mensaje: `sexo debe ser: ${SEXOS.join(', ')}.` });
        }
        if (datos.foto_perfil && !esUrlImagen(datos.foto_perfil)) {
            return res.status(400).json({ ok: false, mensaje: 'foto_perfil debe ser una ruta devuelta por POST /api/archivos.' });
        }
        if (b.fecha_nacimiento !== undefined && b.fecha_nacimiento !== null) {
            if (typeof b.fecha_nacimiento !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(b.fecha_nacimiento)) {
                return res.status(400).json({ ok: false, mensaje: 'fecha_nacimiento debe tener el formato AAAA-MM-DD.' });
            }
            datos.fecha_nacimiento = b.fecha_nacimiento;
        }

        const usuario = await UsuarioModel.actualizarPerfil(req.usuario.id_usuario, datos);
        return res.status(200).json({ ok: true, mensaje: 'Perfil actualizado.', usuario });
    } catch (error) {
        if (typeof error.sqlState === 'string' && /^45\d{3}$/.test(error.sqlState)) {
            return res.status(Number(error.sqlState.slice(2))).json({ ok: false, mensaje: error.sqlMessage });
        }
        console.error('Error en actualizarPerfil:', error);
        return res.status(500).json({ ok: false, mensaje: 'Error interno del servidor.' });
    }
};

// Común a Google y Facebook. Si la persona no tiene cuenta y todavía no eligió
// rol, responde { requiere_rol: true } para que la app le pregunte y reintente.
const loginSocial = (proveedor, verificar) => async (req, res) => {
    try {
        const body = req.body ?? {};
        const persona = await verificar(body);

        let usuario = await UsuarioModel.buscarSocial(proveedor, persona.id, persona.correo);
        let creado = false;

        if (usuario && !usuario.activo) {
            return res.status(403).json({ ok: false, mensaje: 'Esta cuenta está desactivada.' });
        }

        if (!usuario) {
            const id_rol = Number(body.id_rol);
            if (id_rol !== ROLES.CLIENTE && id_rol !== ROLES.TRABAJADOR) {
                return res.status(200).json({
                    ok: true,
                    requiere_rol: true,
                    datos: { nombre: persona.nombre, apellido: persona.apellido, correo: persona.correo }
                });
            }

            // Sin contraseña real: se guarda un hash aleatorio que nadie conoce.
            const contrasena = await bcrypt.hash(crypto.randomBytes(32).toString('hex'), 10);
            const correo = persona.correo || `${proveedor}_${persona.id}@sin-correo.hogarix`;
            const nombre = (persona.nombre || 'Usuario').slice(0, 100);
            const apellido = (persona.apellido || '').slice(0, 100);

            const id_usuario = await UsuarioModel.crearUsuario({
                id_rol, nombre, apellido, correo, contrasena, telefono: null
            });
            await UsuarioModel.vincularSocial(id_usuario, proveedor, persona.id);
            if (persona.foto && esUrlHttps(persona.foto)) {
                await UsuarioModel.actualizarPerfil(id_usuario, { foto_perfil: persona.foto }).catch(() => {});
            }
            usuario = { id_usuario, id_rol, nombre, apellido, correo };
            creado = true;
        }

        const token = firmarToken(usuario.id_usuario, usuario.id_rol);
        return res.status(creado ? 201 : 200).json({
            ok: true,
            mensaje: creado ? 'Cuenta creada.' : 'Inicio de sesión exitoso.',
            token,
            usuario: {
                id_usuario: usuario.id_usuario,
                nombre: usuario.nombre,
                apellido: usuario.apellido,
                correo: usuario.correo,
                id_rol: Number(usuario.id_rol)
            }
        });
    } catch (error) {
        if (error instanceof ErrorSocial) {
            return res.status(error.codigo).json({ ok: false, mensaje: error.message });
        }
        console.error(`Error en login con ${proveedor}:`, error);
        return res.status(500).json({ ok: false, mensaje: `No se pudo iniciar sesión con ${proveedor}.` });
    }
};

const loginGoogle = loginSocial('google', verificarGoogle);
const loginFacebook = loginSocial('facebook', verificarFacebook);

module.exports = {
    registrar,
    login,
    obtenerPerfil,
    actualizarPerfil,
    loginGoogle,
    loginFacebook,
    enviarCodigoCorreo,
    restablecerContrasena,
    accederConCodigo,
    cambiarCorreo,
    cambiarContrasena
};