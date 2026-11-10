// Devuelve un entero positivo o null si el valor no lo es.
const entero = (valor) => {
    if (typeof valor !== 'number' && typeof valor !== 'string') return null;
    const n = Number(valor);
    return Number.isInteger(n) && n > 0 ? n : null;
};

const texto = (valor) => (typeof valor === 'string' ? valor.trim() : '');

const paginacion = (query, limiteMax = 50, limiteDefecto = 20) => {
    const pagina = entero(query.pagina) || 1;
    const limite = Math.min(entero(query.limite) || limiteDefecto, limiteMax);
    return { limite, offset: (pagina - 1) * limite };
};

const esUrlHttps = (valor) => typeof valor === 'string' && valor.length <= 255 && valor.startsWith('https://');

// Imagen válida para guardar en la base: la ruta relativa que devuelve
// POST /api/archivos (/uploads/...) o, por compatibilidad, una URL https externa.
const RUTA_UPLOAD_VALIDA = /^\/uploads\/[A-Za-z0-9_\-/]+\.(jpg|png|webp)$/;
const esUrlImagen = (valor) =>
    typeof valor === 'string' && valor.length <= 255 &&
    (esUrlHttps(valor) || (RUTA_UPLOAD_VALIDA.test(valor) && !valor.includes('//')));

// Convierte una ruta relativa (/uploads/...) en URL absoluta para el cliente.
// Usa PUBLIC_URL si está definida; si no, el host con el que llegó la petición
// (así funciona igual desde localhost, 10.0.2.2 o la IP de la red local).
const urlAbsoluta = (req, ruta) => {
    if (!ruta || /^https?:\/\//.test(ruta)) return ruta;
    const base = (process.env.PUBLIC_URL || `${req.protocol}://${req.get('host')}`).replace(/\/+$/, '');
    return `${base}${ruta}`;
};

// Acepta 'YYYY-MM-DD HH:mm:ss' o cualquier formato ISO 8601 que Date entienda.
const fechaValida = (valor) => {
    if (typeof valor !== 'string' || !valor.trim()) return null;
    const fecha = new Date(valor.replace(' ', 'T'));
    return Number.isNaN(fecha.getTime()) ? null : valor;
};

// Los procedimientos almacenados lanzan SQLSTATE '45XXX' para errores de negocio,
// donde XXX es el código HTTP (400, 403, 404, 409). Cualquier otro error es un 500.
const manejarError = (res, error, contexto) => {
    if (typeof error.sqlState === 'string' && /^45\d{3}$/.test(error.sqlState)) {
        const codigo = parseInt(error.sqlState.slice(2), 10);
        return res.status(codigo >= 400 && codigo <= 599 ? codigo : 400).json({
            ok: false,
            mensaje: error.sqlMessage
        });
    }
    console.error(`Error en ${contexto}:`, error);
    return res.status(500).json({
        ok: false,
        mensaje: 'Error interno del servidor.'
    });
};

const solicitudInvalida = (res, mensaje) => res.status(400).json({ ok: false, mensaje });

const CORREO_VALIDO = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

// Teléfono de México a 10 dígitos. Acepta espacios, guiones, paréntesis y
// lada internacional (+52 / +521). Devuelve null si no son 10 dígitos.
const normalizarTelefono = (valor) => {
    if (typeof valor !== 'string' && typeof valor !== 'number') return null;
    let d = String(valor).replace(/\D/g, '');
    if (d.length === 13 && d.startsWith('521')) d = d.slice(3);
    else if (d.length === 12 && d.startsWith('52')) d = d.slice(2);
    return d.length === 10 ? d : null;
};

module.exports = {
    entero,
    texto,
    paginacion,
    esUrlHttps,
    esUrlImagen,
    urlAbsoluta,
    fechaValida,
    manejarError,
    solicitudInvalida,
    CORREO_VALIDO,
    normalizarTelefono
};
