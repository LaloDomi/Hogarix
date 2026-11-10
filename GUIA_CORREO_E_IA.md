# Guía: correos con código e inteligencia artificial

Esta guía activa tres cosas nuevas de la app:

- **¿Olvidaste tu contraseña?** — llega un código al correo y se crea una contraseña nueva.
- **Continuar con Gmail** — entrar o crear cuenta con un código al correo, sin contraseña
  y **sin cuenta de Google Cloud / Google Developers**.
- **Confirmar el correo al registrarse** — al crear cuenta con correo y contraseña llega un
  código para comprobar que el correo es real.
- **Asistente IA**, botones **"Mejorar con IA"** y **resumen de reseñas con IA**.

Todo es gratis para empezar y no pide tarjeta.

---

## 1. Base de datos (una sola vez)

En MySQL Workbench, conectado a tu base de Aiven:

1. Doble clic en tu base (la que usa la app, por ejemplo `defaultdb` o `servicios_app`) para que quede en **negritas**.
2. *File → Open SQL Script…* → `backend/sql/004_telefono_codigos.sql`.
3. Botón del rayo ⚡.
4. Repite con `backend/sql/005_cambiar_contrasena.sql`.

> Si no aplicas estos scripts, el registro y el login por teléfono y "Cambiar contraseña"
> darán error 500.

Mientras el envío de correos **no** esté configurado (sin Brevo y sin modo de prueba),
el registro con correo se crea directo, sin pedir código, para que la app no se bloquee.

---

## 2. Correos con Brevo (gratis, 300 correos al día)

Render (plan gratis) **bloquea el envío por SMTP** (Gmail con contraseña de aplicación
no funciona ahí). Por eso se usa la API web de Brevo.

Brevo cambia sus menús seguido; estos pasos son los de noviembre de 2026.

**a) Crear la cuenta.** Regístrate gratis en <https://www.brevo.com>. Si al entrar te
pregunta qué quieres hacer, elige lo más parecido a "enviar correos transaccionales" o
sáltalo; no hace falta comprar nada ni poner tarjeta.

**b) Agregar tu Gmail como remitente.**
1. Arriba a la derecha, haz clic en el nombre de tu cuenta/organización → **Settings** (Configuración).
2. En el menú de la izquierda: **Senders, Domains, IPs** → pestaña **Senders**.
3. **Add a sender**. En *From name* pon `Hogarix` y en *From email* tu Gmail.
4. **Save**. Brevo te manda un **código de 6 dígitos** a ese Gmail: cópialo, pégalo y da clic en **Verify sender**.

Verás un ícono de advertencia en DKIM/DMARC: es normal con un Gmail (Brevo solo
puede autenticar dominios propios). Los correos sí se envían; solo es más probable que
caigan en spam al principio.

**c) Crear la clave de la API.**
1. Otra vez **Settings** → en la izquierda, dentro de *Organisation settings*, **SMTP & API**.
2. Abre la pestaña **API keys & MCP** (antes se llamaba solo *API keys*).
   *No uses la pestaña SMTP*: la clave SMTP no sirve para esto.
3. **+ Generate API key**. Ponle un nombre (por ejemplo `hogarix-render`) y en
   *Expiry* elige la duración más larga o sin vencimiento.
4. **Generate** y copia la clave **en ese momento** (empieza con `xkeysib-`); Brevo no
   la vuelve a mostrar. Si la pierdes, genera otra.

**d) Permitir las IPs de Render (importante).** Brevo deja usar la clave desde
cualquier IP durante los primeros 30 días y después bloquea las IPs nuevas. Las IPs de
Render cambian, así que un día los correos dejarían de salir. Para evitarlo:
**Settings → Security → Authorized IPs** → si dice *Activated*, clic en
**Deactivate blocking** y confirma. Si en el log de Render ves un error de Brevo
`unauthorized: IP not authorized` o `not verified`, es esto.

**e) Ponerlo en Render.** Tu servicio → **Environment** → agrega:

| Variable | Valor |
|---|---|
| `BREVO_API_KEY` | la clave `xkeysib-...` del paso c |
| `CORREO_REMITENTE` | el Gmail que verificaste en el paso b (exactamente igual) |
| `CORREO_REMITENTE_NOMBRE` | `Hogarix` (o el nombre que quieras) |

Render reinicia solo el servidor. Prueba en la app: *Iniciar sesión → ¿Olvidaste tu contraseña?*

**Para probar en tu PC sin Brevo:** en tu `.env` local pon `CORREO_MODO_PRUEBA=true`.
El código no se envía; aparece en la ventana negra del backend. No lo actives en Render.

> Si los correos llegan a spam: es normal al principio con un remitente Gmail. Pide a los
> primeros usuarios marcarlo como "No es spam". Más adelante, con un dominio propio
> verificado en Brevo, llegan mejor.

---

## 3. Inteligencia artificial con Groq (gratis)

1. Entra a <https://console.groq.com/keys> (puedes entrar con GitHub o correo).
2. **Create API Key** y cópiala (empieza con `gsk_`).
3. En Render → **Environment** agrega:

| Variable | Valor |
|---|---|
| `IA_API_KEY` | tu clave de Groq |
| `IA_MODELO` | `openai/gpt-oss-120b` (es el valor por defecto; las cuentas nuevas de Groq no siempre tienen los modelos Llama) |

Listo: aparece el **Asistente IA** en el Inicio del cliente y en *Más* del trabajador;
el botón **Mejorar con IA** en: publicar un trabajo, agregar/editar servicio, la
descripción del perfil del trabajador y el detalle de una solicitud; y la tarjeta
**"Lo que dicen los clientes"** en las reseñas de cada trabajador (con 3 o más reseñas
con comentario; el resumen se guarda 12 horas o hasta que llegue otra reseña).

Para cuidar la cuota gratis, cada usuario puede hacer 20 consultas cada 5 minutos.

**¿Otro proveedor?** Cualquiera compatible con la API de OpenAI funciona cambiando
`IA_API_URL`, `IA_API_KEY` e `IA_MODELO` (OpenAI, OpenRouter, Gemini en su endpoint
`/openai`, etc.). Si el proveedor no acepta `response_format`, pon `IA_MODO_JSON=false`.

---

## 4. Rutas nuevas del backend

| Método y ruta | Para qué |
|---|---|
| `POST /api/auth/login` | Ahora acepta `{ identificador, contrasena }` con correo **o** teléfono (sigue aceptando `correo`) |
| `POST /api/auth/registro` | `correo` opcional si se manda `telefono` (10 dígitos). Con correo responde `202 { requiere_codigo: true }` y hay que repetir con `codigo` |
| `PUT /api/auth/contrasena` | (con sesión) `{ actual, nueva }` cambiar la contraseña |
| `POST /api/auth/codigo` | `{ correo, proposito: "restablecer" \| "acceso" }` manda el código |
| `POST /api/auth/contrasena/restablecer` | `{ correo, codigo, contrasena }` |
| `POST /api/auth/codigo/verificar` | `{ correo, codigo, id_rol?, nombre?, apellido? }` entrar con Gmail |
| `PUT /api/auth/correo` | (con sesión) `{ correo, codigo }` agregar o cambiar el correo |
| `POST /api/ia/asistente` | (con sesión) `{ mensajes: [{ rol, texto }] }` |
| `POST /api/ia/mejorar-texto` | (con sesión) `{ texto, tipo, titulo?, categoria? }` |
| `GET /api/ia/resumen-resenas/:id_usuario` | (con sesión) resumen de las reseñas de un trabajador |

Los códigos duran 15 minutos, se guardan cifrados (hash), permiten 5 intentos y se
puede pedir uno cada 45 segundos (máximo 5 cada 15 minutos).

## Limitación del registro por teléfono

El número **no se verifica por SMS** (los SMS cuestan dinero en todos los proveedores).
Quien se registra solo con teléfono puede agregar un correo en *Editar perfil* para
poder recuperar su contraseña; la app se lo sugiere.

## Notificaciones

Con la app abierta, cada 45 segundos (y al volver a la app) se revisan las
notificaciones: el contador de la campana se actualiza y aparece un aviso con botón
**Ver** cuando llega una nueva (solicitud nueva, solicitud aceptada, visita, etc.).

Las notificaciones **con la app cerrada** (push del sistema) necesitan Firebase Cloud
Messaging: una cuenta gratuita de Firebase y el archivo `google-services.json`.
El backend ya tiene la tabla y la ruta `POST /api/dispositivos` para guardar el token
del teléfono cuando se active.
