const { pedirJson } = require('./peticionHttp');

// Envío de correos con la API HTTP de Brevo (gratis: 300 correos al día).
// Se usa la API y no SMTP porque Render (plan gratis) bloquea los puertos SMTP.
//
// Variables de entorno:
//   BREVO_API_KEY         clave de Brevo (Settings > SMTP & API > API Keys)
//   CORREO_REMITENTE      correo verificado en Brevo como remitente (puede ser tu Gmail)
//   CORREO_REMITENTE_NOMBRE  nombre que verán las personas (por defecto "Hogarix")
//   CORREO_MODO_PRUEBA=true  sin Brevo: el código solo se imprime en la consola del
//                            servidor (para probar en local). No usar en producción.

class ErrorCorreo extends Error {
    constructor(mensaje, codigo = 503) {
        super(mensaje);
        this.codigo = codigo;
    }
}

const escaparHtml = (s) => String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
}[c]));

const plantillaCodigo = ({ titulo, explicacion, codigo, minutos }) => `
<!doctype html>
<html><body style="margin:0;background:#0A1730;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:32px 12px;">
    <tr><td align="center">
      <table width="100%" cellpadding="0" cellspacing="0" style="max-width:460px;background:#14284B;border-radius:16px;padding:28px;color:#ffffff;">
        <tr><td style="font-size:26px;font-weight:800;">Oficio<span style="color:#5CA8FF;">Link</span></td></tr>
        <tr><td style="padding-top:18px;font-size:18px;font-weight:700;">${escaparHtml(titulo)}</td></tr>
        <tr><td style="padding-top:8px;font-size:14px;color:#9FB0CC;line-height:1.5;">${escaparHtml(explicacion)}</td></tr>
        <tr><td align="center" style="padding:24px 0;">
          <div style="display:inline-block;background:#0A1730;border:1px solid #223A63;border-radius:12px;padding:14px 22px;font-size:32px;letter-spacing:8px;font-weight:800;color:#5CA8FF;">${escaparHtml(codigo)}</div>
        </td></tr>
        <tr><td style="font-size:13px;color:#9FB0CC;line-height:1.5;">
          El código vence en ${minutos} minutos. Si tú no lo pediste, ignora este correo: tu cuenta sigue segura.
        </td></tr>
      </table>
    </td></tr>
  </table>
</body></html>`;

// true si el servidor puede mandar correos (Brevo o modo de prueba).
const correoConfigurado = () =>
    Boolean(process.env.BREVO_API_KEY && process.env.CORREO_REMITENTE)
    || String(process.env.CORREO_MODO_PRUEBA).toLowerCase() === 'true';

const enviarCorreo = async ({ para, asunto, html, texto }) => {
    const clave = process.env.BREVO_API_KEY;
    const remitente = process.env.CORREO_REMITENTE;

    if (!clave || !remitente) {
        if (String(process.env.CORREO_MODO_PRUEBA).toLowerCase() === 'true') {
            console.log(`\n[CORREO DE PRUEBA] Para: ${para}\nAsunto: ${asunto}\n${texto}\n`);
            return { simulado: true };
        }
        throw new ErrorCorreo('El envío de correos no está configurado en el servidor (faltan BREVO_API_KEY y CORREO_REMITENTE).');
    }

    const { status, json } = await pedirJson({
        url: 'https://api.brevo.com/v3/smtp/email',
        headers: { 'api-key': clave },
        cuerpo: {
            sender: { email: remitente, name: process.env.CORREO_REMITENTE_NOMBRE || 'Hogarix' },
            to: [{ email: para }],
            subject: asunto,
            htmlContent: html,
            textContent: texto
        }
    });

    if (status < 200 || status >= 300) {
        console.error('Brevo rechazó el correo:', status, json);
        throw new ErrorCorreo('No se pudo enviar el correo. Intenta de nuevo en unos minutos.', 502);
    }
    return { simulado: false };
};

const PROPOSITOS = {
    restablecer: {
        asunto: 'Tu código para restablecer la contraseña',
        titulo: 'Restablece tu contraseña',
        explicacion: 'Escribe este código en la app para crear una contraseña nueva.'
    },
    registro: {
        asunto: 'Tu código para confirmar tu correo',
        titulo: 'Confirma tu correo',
        explicacion: 'Escribe este código en la app para terminar de crear tu cuenta.'
    },
    acceso: {
        asunto: 'Tu código para entrar a OficioLink',
        titulo: 'Entra a tu cuenta',
        explicacion: 'Escribe este código en la app para entrar o crear tu cuenta con este correo. No necesitas contraseña.'
    }
};

const enviarCodigo = ({ para, codigo, proposito, minutos }) => {
    const p = PROPOSITOS[proposito];
    return enviarCorreo({
        para,
        asunto: `${codigo} es ${p.asunto.toLowerCase()}`,
        html: plantillaCodigo({ titulo: p.titulo, explicacion: p.explicacion, codigo, minutos }),
        texto: `${p.titulo}\n\n${p.explicacion}\n\nCódigo: ${codigo}\n\nVence en ${minutos} minutos. Si tú no lo pediste, ignora este correo.`
    });
};

module.exports = { enviarCorreo, enviarCodigo, correoConfigurado, ErrorCorreo };
