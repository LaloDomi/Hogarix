const https = require('https');

// GET a una URL https y devuelve el JSON. Usa el módulo https de Node para no
// depender de la versión de Node (fetch no existe en versiones viejas).
const obtenerJson = (url, headers = {}) =>
    new Promise((resolve, reject) => {
        const req = https.get(url, { headers, timeout: 10000 }, (res) => {
            let cuerpo = '';
            res.setEncoding('utf8');
            res.on('data', (parte) => { cuerpo += parte; });
            res.on('end', () => {
                let json = null;
                try { json = JSON.parse(cuerpo); } catch (_) { /* no era JSON */ }
                resolve({ status: res.statusCode, json });
            });
        });
        req.on('timeout', () => req.destroy(new Error('Tiempo de espera agotado')));
        req.on('error', reject);
    });

// Error con mensaje para el usuario y código HTTP.
class ErrorSocial extends Error {
    constructor(mensaje, codigo = 401) {
        super(mensaje);
        this.codigo = codigo;
    }
}

const idsCliente = () =>
    (process.env.GOOGLE_CLIENT_IDS || process.env.GOOGLE_CLIENT_ID || '')
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);

// Valida un id_token o un access_token de Google y devuelve los datos de la persona.
const verificarGoogle = async ({ id_token, access_token }) => {
    const permitidos = idsCliente();
    if (!permitidos.length) {
        throw new ErrorSocial('El inicio con Google no está configurado en el servidor (falta GOOGLE_CLIENT_IDS en .env).', 503);
    }

    if (id_token) {
        const { status, json } = await obtenerJson(
            `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(id_token)}`
        );
        if (status !== 200 || !json?.sub) throw new ErrorSocial('La sesión de Google no es válida. Intenta de nuevo.');
        if (!permitidos.includes(json.aud)) throw new ErrorSocial('Este inicio de sesión de Google no pertenece a la app.', 403);
        return {
            id: String(json.sub),
            correo: json.email_verified === 'true' || json.email_verified === true ? json.email : null,
            nombre: json.given_name || json.name || '',
            apellido: json.family_name || '',
            foto: json.picture || null
        };
    }

    if (access_token) {
        const info = await obtenerJson(
            `https://oauth2.googleapis.com/tokeninfo?access_token=${encodeURIComponent(access_token)}`
        );
        if (info.status !== 200 || !info.json?.sub) throw new ErrorSocial('La sesión de Google no es válida. Intenta de nuevo.');
        if (!permitidos.includes(info.json.aud) && !permitidos.includes(info.json.azp)) {
            throw new ErrorSocial('Este inicio de sesión de Google no pertenece a la app.', 403);
        }
        const perfil = await obtenerJson('https://www.googleapis.com/oauth2/v3/userinfo', {
            Authorization: `Bearer ${access_token}`
        });
        const p = perfil.json || {};
        return {
            id: String(info.json.sub),
            correo: p.email_verified ? p.email : (info.json.email || null),
            nombre: p.given_name || p.name || '',
            apellido: p.family_name || '',
            foto: p.picture || null
        };
    }

    throw new ErrorSocial('Falta id_token o access_token de Google.', 400);
};

// Valida un access_token de Facebook contra la app configurada.
const verificarFacebook = async ({ access_token }) => {
    const appId = process.env.FACEBOOK_APP_ID;
    const secreto = process.env.FACEBOOK_APP_SECRET;
    if (!appId || !secreto) {
        throw new ErrorSocial('El inicio con Facebook no está configurado en el servidor (faltan FACEBOOK_APP_ID y FACEBOOK_APP_SECRET en .env).', 503);
    }
    if (!access_token) throw new ErrorSocial('Falta access_token de Facebook.', 400);

    const tokenApp = `${appId}|${secreto}`;
    const debug = await obtenerJson(
        `https://graph.facebook.com/debug_token?input_token=${encodeURIComponent(access_token)}&access_token=${encodeURIComponent(tokenApp)}`
    );
    const d = debug.json?.data;
    if (debug.status !== 200 || !d?.is_valid || String(d.app_id) !== String(appId)) {
        throw new ErrorSocial('La sesión de Facebook no es válida. Intenta de nuevo.');
    }

    const yo = await obtenerJson(
        `https://graph.facebook.com/me?fields=id,first_name,last_name,email,picture.type(large)&access_token=${encodeURIComponent(access_token)}`
    );
    if (yo.status !== 200 || !yo.json?.id) throw new ErrorSocial('No se pudieron leer tus datos de Facebook.');
    return {
        id: String(yo.json.id),
        correo: yo.json.email || null,
        nombre: yo.json.first_name || '',
        apellido: yo.json.last_name || '',
        foto: yo.json.picture?.data?.url || null
    };
};

module.exports = { verificarGoogle, verificarFacebook, ErrorSocial };
