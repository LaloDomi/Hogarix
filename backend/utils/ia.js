const { pedirJson } = require('./peticionHttp');

// Cliente de IA compatible con la API de "chat completions" de OpenAI.
// Por defecto usa Groq (gratis, sin tarjeta): https://console.groq.com/keys
//
// Variables de entorno:
//   IA_API_KEY   clave del proveedor (obligatoria para usar la IA)
//   IA_API_URL   por defecto https://api.groq.com/openai/v1/chat/completions
//   IA_MODELO    por defecto llama-3.3-70b-versatile
//   IA_MODO_JSON=false  si tu proveedor no acepta response_format (json_object)
//
// Otros proveedores compatibles: OpenAI, OpenRouter, Gemini (endpoint /openai), etc.
// Solo cambia IA_API_URL, IA_API_KEY e IA_MODELO.

class ErrorIA extends Error {
    constructor(mensaje, codigo = 502) {
        super(mensaje);
        this.codigo = codigo;
    }
}

const config = () => ({
    url: process.env.IA_API_URL || 'https://api.groq.com/openai/v1/chat/completions',
    clave: process.env.IA_API_KEY,
    modelo: process.env.IA_MODELO || 'llama-3.3-70b-versatile'
});

const iaConfigurada = () => Boolean(config().clave);

/**
 * @param {object} p
 * @param {string} p.sistema  instrucciones del sistema
 * @param {{role:'user'|'assistant', content:string}[]} p.mensajes
 * @param {boolean} [p.json]  pide la respuesta como objeto JSON
 */
const completar = async ({ sistema, mensajes, json = false, maxTokens = 600, temperatura = 0.5 }) => {
    const { url, clave, modelo } = config();
    if (!clave) {
        throw new ErrorIA('El asistente de IA no está configurado en el servidor (falta IA_API_KEY).', 503);
    }

    const cuerpo = {
        model: modelo,
        messages: [{ role: 'system', content: sistema }, ...mensajes],
        max_tokens: maxTokens,
        temperature: temperatura
    };
    if (json && String(process.env.IA_MODO_JSON).toLowerCase() !== 'false') {
        cuerpo.response_format = { type: 'json_object' };
    }

    let respuesta;
    try {
        respuesta = await pedirJson({
            url,
            headers: { Authorization: `Bearer ${clave}` },
            cuerpo,
            timeoutMs: 30000
        });
    } catch (error) {
        console.error('IA sin conexión:', error.message);
        throw new ErrorIA('No se pudo conectar con el asistente de IA. Intenta de nuevo.');
    }

    const { status, json: r } = respuesta;
    if (status === 429) throw new ErrorIA('El asistente está muy ocupado. Intenta de nuevo en un minuto.', 429);
    if (status < 200 || status >= 300) {
        console.error('El proveedor de IA respondió', status, JSON.stringify(r)?.slice(0, 500));
        throw new ErrorIA('El asistente de IA no respondió. Intenta de nuevo.');
    }

    const contenido = r?.choices?.[0]?.message?.content;
    if (typeof contenido !== 'string' || !contenido.trim()) {
        throw new ErrorIA('El asistente de IA no dio una respuesta. Intenta de nuevo.');
    }
    return contenido.trim();
};

// Saca el primer objeto JSON del texto (por si el modelo agregó algo alrededor).
const leerJson = (textoModelo) => {
    try {
        return JSON.parse(textoModelo);
    } catch (_) {
        const m = textoModelo.match(/\{[\s\S]*\}/);
        if (!m) return null;
        try { return JSON.parse(m[0]); } catch (_) { return null; }
    }
};

module.exports = { completar, leerJson, iaConfigurada, ErrorIA };
