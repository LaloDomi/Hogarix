const https = require('https');

// Petición HTTPS que manda y recibe JSON. Usa el módulo https de Node (igual
// que proveedoresSociales.js) para no depender de la versión de Node.
// Devuelve { status, json } y nunca lanza por códigos 4xx/5xx; solo por red.
const pedirJson = ({ metodo = 'POST', url, headers = {}, cuerpo, timeoutMs = 20000 }) =>
    new Promise((resolve, reject) => {
        const datos = cuerpo === undefined ? null : Buffer.from(JSON.stringify(cuerpo));
        const req = https.request(url, {
            method: metodo,
            timeout: timeoutMs,
            headers: {
                Accept: 'application/json',
                ...(datos ? { 'Content-Type': 'application/json', 'Content-Length': datos.length } : {}),
                ...headers
            }
        }, (res) => {
            let texto = '';
            res.setEncoding('utf8');
            res.on('data', (parte) => { texto += parte; });
            res.on('end', () => {
                let json = null;
                try { json = JSON.parse(texto); } catch (_) { /* no era JSON */ }
                resolve({ status: res.statusCode, json });
            });
        });
        req.on('timeout', () => req.destroy(new Error('Tiempo de espera agotado')));
        req.on('error', reject);
        if (datos) req.write(datos);
        req.end();
    });

module.exports = { pedirJson };
