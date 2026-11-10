# app_jenny — Documentación técnica

Backend REST en Node.js/Express + MySQL para la app de servicios/trabajos. Para una descripción funcional no técnica, ver [README.md](README.md).

## Stack

- Node.js + Express 5
- MySQL 8 (probado contra 8.0.42), driver `mysql2/promise` con pool de conexiones
- Autenticación: `jsonwebtoken` + `bcryptjs`
- Subida de archivos: `multer` (en memoria, validado y luego escrito a disco)
- Sin Firebase: chat, notificaciones e imágenes viven en MySQL + disco del servidor
- Toda la lógica de negocio y las consultas viven en **procedimientos almacenados**; el código JS no arma SQL a mano (decisión explícita del proyecto para no exponer las consultas).

## Estructura

```
app.js                  # registro de middlewares globales y montaje de routers
server.js                # arranque del servidor (lee PORT)
config/
  db.js                  # pool mysql2 (lee DB_HOST, DB_USER, DB_PASSWORD, DB_NAME)
  constantes.js           # ROLES, TIPOS_PAGO, ESTADOS_SOLICITUD, PLATAFORMAS, TIPOS_NOTIFICACION, CHAT
  almacenamiento.js       # UPLOADS_DIR, límites y detección de tipo de imagen para multer
middlewares/
  authMiddleware.js       # verificarToken, verificarRol(...roles)
utils/
  helpers.js              # entero, texto, paginacion, esUrlHttps, esUrlImagen, urlAbsoluta, fechaValida, manejarError, solicitudInvalida
  notificar.js            # notificar(id_usuario, {...}): crea una notificación sin lanzar errores
routes/ · controllers/ · models/
  un archivo por módulo, mismo nombre en los tres (p. ej. agendaRoutes.js -> agendaController.js -> agendaModel.js)
database/                 # (ignorada por git) schema.sql original
sql/
  001_chat_archivos_notificaciones.sql   # migración versionada: tablas + procedimientos nuevos
uploads/                  # (ignorada por git) imágenes subidas, servidas en /uploads
```

## Migraciones

A partir de ahora los cambios de base de datos se versionan en `sql/` con un número consecutivo. Cada archivo es re-ejecutable (`CREATE TABLE IF NOT EXISTS`, `DROP PROCEDURE IF EXISTS`).

```bash
mysql -u root -p servicios_app < sql/001_chat_archivos_notificaciones.sql
```

`001` agrega las tablas `archivos`, `conversaciones`, `mensajes` y `notificaciones`, la función `fn_hay_bloqueo` y sus procedimientos. Antes de crear nada verifica el esquema existente y se detiene con un mensaje claro si no coincide:

- `usuarios` debe tener `id_usuario` (INT con signo), `nombre`, `apellido`, `activo`.
- `bloqueos` debe tener `id_usuario` (quien bloquea) e `id_bloqueado`. Si en la base real se llaman distinto, solo hay que ajustar `fn_hay_bloqueo` (único lugar que las usa) y la verificación del inicio del script.

**Importante:** `database/schema.sql` quedó desactualizado. Las tablas y procedimientos agregados después (reseñas, favoritos, reportes, bloqueos, likes, imágenes de portafolio, dispositivos de notificación, `eventos_agenda`) se entregaron como scripts SQL sueltos en la conversación y se aplicaron directo a la base, pero no se consolidaron en ese archivo. Si necesitas recrear la base desde cero, hay que juntar esos scripts — decir si se quiere que se centralicen en un solo archivo versionado.

## Variables de entorno (`.env`)

```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=...
DB_NAME=servicios_app
PORT=3001
JWT_SECRET=...   # obligatorio: sin fallback en código, la app falla si falta
UPLOADS_DIR=...  # opcional: carpeta de imágenes subidas (por defecto ./uploads)
PUBLIC_URL=...   # opcional: URL pública del servidor para armar URLs absolutas (por defecto, el host de la petición)
```

## Patrón de capas

```
Cliente HTTP
  -> routes/*.js            (define método + path, aplica middlewares)
  -> middlewares/authMiddleware.js  (verificarToken castea el JWT a req.usuario = {id_usuario, id_rol}; verificarRol(...) filtra por rol)
  -> controllers/*.js        (valida forma/tipos del input con utils/helpers.js, nunca reglas de negocio; llama al model; arma la respuesta HTTP)
  -> models/*.js             (una clase con métodos static; cada método hace un solo `CALL sp_...(...)`)
  -> MySQL: procedimiento almacenado (reglas de negocio, validaciones que dependen del estado en BD, transacciones)
```

Motivo de esta separación: los controllers validan *forma* (¿es un entero?, ¿trae los campos obligatorios?, ¿el enum es válido?) devolviendo 400 antes de tocar la base. Los procedimientos validan *negocio* (¿existe?, ¿te pertenece?, ¿el estado lo permite?, ¿hay traslape?) usando `SIGNAL SQLSTATE`.

### Convención de errores de negocio

Los procedimientos usan `SIGNAL SQLSTATE '45xxx'` donde `xxx` es el código HTTP que debe responder Express:

```sql
SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Recurso no encontrado.';
```

`utils/helpers.js#manejarError` intercepta esto: si `error.sqlState` matchea `/^45\d{3}$/`, responde con ese código HTTP y el `sqlMessage` tal cual (pensado para mostrarse al usuario). Cualquier otro error cae a 500 genérico y se loggea con `console.error`. Todos los controllers siguen el mismo patrón:

```js
try {
  ...
} catch (error) {
  return manejarError(res, error, 'nombreDeLaFuncion');
}
```

### Transacciones y variables de sesión

Cuando un flujo necesita más de un statement atómico en el mismo `CALL` (por ejemplo un `OUT` parameter, o insertar una fila y sus imágenes), el model toma una conexión dedicada del pool (`db.getConnection()`) en vez de usar `db.query` directo, porque `pool.query` puede resolver cada llamada en una conexión distinta y las variables de sesión (`@variable`) o transacciones no persistirían entre ellas. Ver `usuarioModel.crearUsuario` (usa `OUT` + `@id_usuario`) y `publicacionModel.crear` (transacción JS con `beginTransaction`/`commit`/`rollback` porque inserta N imágenes en un loop).

Los demás procedimientos multi-statement (agenda, servicios, etc.) manejan su propia transacción **dentro** del procedimiento con `START TRANSACTION` / `DECLARE EXIT HANDLER FOR SQLEXCEPTION ROLLBACK`, así que el model solo hace un `CALL` simple con `db.query` (pool), sin necesitar conexión dedicada.

## Autenticación y roles

- Login/registro devuelven un JWT firmado con `JWT_SECRET`, payload `{ id_usuario, id_rol }`, expira en 30 días (pendiente de acortar + refresh token antes de producción).
- `verificarToken`: exige header `Authorization: Bearer <token>`, castea el payload a `req.usuario`.
- `verificarRol(...roles)`: factory que compara `req.usuario.id_rol` (Number) contra la lista de roles permitidos. `config/constantes.js` fija `ROLES.CLIENTE = 1`, `ROLES.TRABAJADOR = 2` — **asume ese mapeo en la tabla `roles`**; si cambia, hay que actualizar la constante.
- No hay revocación de tokens ni blacklist; el logout es responsabilidad del cliente (borrar el token guardado).

## Mapa de endpoints

`Auth` = requiere `verificarToken`. `Rol` = además requiere ese rol.

| Módulo | Método y ruta | Auth | Rol |
|---|---|---|---|
| Auth | `POST /api/auth/registro` | — | — |
| Auth | `POST /api/auth/login` | — | — |
| Auth | `GET /api/auth/perfil` | Sí | — |
| Auth | `PUT /api/auth/perfil` (nombre, apellido, telefono, foto_perfil, estado_mx, municipio, colonia, fecha_nacimiento, sexo) | Sí | — |
| Auth | `POST /api/auth/google` (`id_token` o `access_token`, `id_rol?`) | — | — |
| Auth | `POST /api/auth/facebook` (`access_token`, `id_rol?`) | — | — |
| Salud | `GET /api/salud` (servidor + MySQL) | — | — |
| Categorías | `GET /api/categorias` | — | — |
| Servicios | `GET /api/servicios/buscar?id_categoria=&tipo_pago=` | — | — |
| Trabajador | `GET /api/trabajadores/:id_usuario` | — | — |
| Trabajador | `PUT /api/trabajadores/perfil` | Sí | Trabajador |
| Trabajador | `POST /api/trabajadores/servicios` | Sí | Trabajador |
| Trabajador | `PUT /api/trabajadores/servicios/:id_servicio` | Sí | Trabajador |
| Trabajador | `DELETE /api/trabajadores/servicios/:id_servicio` | Sí | Trabajador |
| Publicaciones | `GET /api/publicaciones?id_usuario=&pagina=&limite=` | Sí | — |
| Publicaciones | `POST /api/publicaciones` | Sí | — |
| Publicaciones | `GET /api/publicaciones/:id_publicacion` | Sí | — |
| Publicaciones | `DELETE /api/publicaciones/:id_publicacion` | Sí | — |
| Publicaciones | `GET/POST /api/publicaciones/:id_publicacion/comentarios` | Sí | — |
| Publicaciones | `DELETE /api/publicaciones/:id_publicacion/comentarios/:id_comentario` | Sí | — |
| Publicaciones | `POST/DELETE /api/publicaciones/:id_publicacion/like` | Sí | — |
| Solicitudes | `POST /api/solicitudes` | Sí | Cliente |
| Solicitudes | `GET /api/solicitudes?estado=&pagina=&limite=` | Sí | — |
| Solicitudes | `GET /api/solicitudes/:id_solicitud` | Sí | — |
| Solicitudes | `PATCH /api/solicitudes/:id_solicitud/estado` | Sí | — |
| Reseñas | `POST /api/resenas` | Sí | — |
| Reseñas | `GET /api/resenas/usuario/:id_usuario` | — | — |
| Favoritos | `GET /api/favoritos` | Sí | Cliente |
| Favoritos | `POST/DELETE /api/favoritos/:id_trabajador` | Sí | Cliente |
| Moderación | `POST /api/reportes` | Sí | — |
| Moderación | `GET /api/bloqueos` | Sí | — |
| Moderación | `POST/DELETE /api/bloqueos/:id_usuario` | Sí | — |
| Dispositivos | `POST/DELETE /api/dispositivos` (body `token_fcm`) | Sí | — |
| Agenda | `GET /api/agenda?desde=&hasta=` | Sí | — |
| Agenda | `POST /api/agenda` | Sí | — |
| Agenda | `PUT/DELETE /api/agenda/:id_evento` | Sí | — |
| Visitas | `GET /api/visitas?desde=&hasta=` | Sí | — |
| Visitas | `POST /api/visitas` (id_solicitud, fecha_inicio, fecha_fin, direccion?, notas?) | Sí | — |
| Visitas | `PUT /api/visitas/:id_visita` (reprogramar; vuelve a "Propuesta") | Sí | — |
| Visitas | `PATCH /api/visitas/:id_visita/estado` (Confirmada, Cancelada, Realizada) | Sí | — |
| Archivos | `POST /api/archivos` (multipart, campo `archivo`) | Sí | — |
| Chat | `GET /api/conversaciones?pagina=&limite=` | Sí | — |
| Chat | `POST /api/conversaciones` (body `id_usuario`) | Sí | — |
| Chat | `GET /api/conversaciones/no-leidos` | Sí | — |
| Chat | `GET /api/conversaciones/:id_conversacion/mensajes?despues_de=&antes_de=&limite=` | Sí | — |
| Chat | `POST /api/conversaciones/:id_conversacion/mensajes` (body `contenido?`, `url_imagen?`) | Sí | — |
| Chat | `PATCH /api/conversaciones/:id_conversacion/leida` | Sí | — |
| Notificaciones | `GET /api/notificaciones?no_leidas=&pagina=&limite=` | Sí | — |
| Notificaciones | `GET /api/notificaciones/no-leidas` | Sí | — |
| Notificaciones | `PATCH /api/notificaciones/leidas` (todas) | Sí | — |
| Notificaciones | `PATCH /api/notificaciones/:id_notificacion/leida` | Sí | — |

Formato de respuesta uniforme: `{ ok: boolean, mensaje?: string, data?: any, total?: number }`. Las rutas inexistentes bajo `/api` y el JSON malformado también responden con ese formato (404 y 400).

## Visitas (migración 003)

- Una visita pertenece a una solicitud `Pendiente` o `Aceptado`; la propone cliente o trabajador.
- La otra persona la confirma (`Confirmada`). Cualquiera la cancela o la reprograma; al reprogramar vuelve a `Propuesta` y le toca confirmar al otro.
- Solo el trabajador la marca como `Realizada` (desde `Confirmada`).
- `sp_visita_verificar_horario` rechaza (409) choques con otra visita activa del trabajador o con su agenda personal.
- Cada cambio genera una notificación de tipo `visita` para la otra persona.

## Inicio de sesión social

`utils/proveedoresSociales.js` valida el token directamente con Google (`tokeninfo`) o Facebook (`debug_token`) usando `GOOGLE_CLIENT_IDS`, `FACEBOOK_APP_ID` y `FACEBOOK_APP_SECRET` del `.env`. Busca por `id_google`/`id_facebook`, luego por correo (y vincula). Si no existe y no viene `id_rol`, responde `{ ok: true, requiere_rol: true }` para que la app pregunte el rol. Ver `GUIA_LOGIN_SOCIAL.md`.

## Imágenes

1. El cliente sube la imagen a `POST /api/archivos` (multipart/form-data, campo `archivo`).
2. Se recibe en memoria (máx. 5 MB), se valida el tipo real por sus primeros bytes (JPG, PNG o WEBP; si no, 415) y se escribe en `UPLOADS_DIR/imagenes/AAAA/MM/<uuid>.<ext>`. Se registra en la tabla `archivos`.
3. La respuesta trae `ruta` (`/uploads/imagenes/...`, **lo que se guarda en la base**) y `url` (absoluta, para mostrarla de inmediato).
4. Esa `ruta` se manda en `imagenes` de una publicación o en `url_imagen` de un mensaje. `esUrlImagen` acepta esas rutas o URLs `https://` externas.
5. Se guarda la ruta relativa (no la absoluta) porque el host cambia según desde dónde se conecte la app (`localhost`, `10.0.2.2` en el emulador, la IP de la red). El cliente le antepone la dirección del servidor para mostrarla.

## Chat

- Una conversación por par de usuarios (`id_usuario_1 < id_usuario_2`, único). `POST /api/conversaciones` la crea o devuelve la existente.
- La bandeja (`GET /api/conversaciones`) solo muestra conversaciones con al menos un mensaje, la más reciente primero, con el último mensaje y `no_leidos`.
- Lectura: cada lado guarda `ultimo_leido_N` (id del último mensaje visto). `PATCH .../leida` lo actualiza; cada mensaje trae `leido` = si el otro ya lo vio.
- Tiempo real por consulta periódica: la app pide `GET .../mensajes?despues_de=<último id que tiene>` cada pocos segundos. Para el historial anterior usa `antes_de=<id más viejo>`. Sin parámetros devuelve los últimos `limite` (30 por defecto, máx. 100), siempre en orden cronológico.
- Bloqueos (`fn_hay_bloqueo`): con bloqueo en cualquier dirección no se puede iniciar ni enviar (403), y la conversación se oculta de la bandeja.

## Notificaciones

- Solo dentro de la app (tabla `notificaciones`); no hay push.
- Se generan desde los controllers con `utils/notificar.js`, que nunca lanza error, así un fallo al notificar no rompe la acción principal.
- Eventos actuales: `solicitud_nueva` (al trabajador cuando le crean una solicitud) y `solicitud_estado` (a la otra parte cuando la solicitud se acepta, rechaza, completa o cancela). `id_referencia` = `id_solicitud`.
- Para saber a quién avisar en un cambio de estado se leen `id_cliente` e `id_trabajador` del resultado de `sp_solicitud_cambiar_estado` o, si no vienen, de `sp_solicitud_listar`. Si los procedimientos usan otros nombres de columna, el cambio de estado funciona igual pero no se genera el aviso — ajustar `otraParte` en `solicitudController.js`.
- El módulo `dispositivos` (token FCM) se conserva sin uso por si más adelante se agregan notificaciones push.

## Reglas de negocio implementadas en procedimientos (resumen)

- **Publicaciones/comentarios/likes**: se ocultan entre usuarios con bloqueo mutuo (`bloqueos`); las publicaciones y usuarios usan soft delete (`activo`), nunca se borran físicamente salvo comentarios/likes propios.
- **Solicitudes**: no se puede solicitar a uno mismo; solo el trabajador acepta/rechaza desde `Pendiente`; cualquiera cancela desde `Pendiente`/`Aceptado`; solo se completa desde `Aceptado`.
- **Reseñas**: solo sobre solicitudes en estado `Completado`, una reseña por autor por solicitud, calificación 1-5 (`CHECK` + validación en procedimiento).
- **Agenda**: valida `fecha_fin > fecha_inicio` y rechaza traslapes con otro evento del mismo trabajador (`SIGNAL '45409'`).
- **Roles**: el registro (`sp_usuario_crear`) crea automáticamente un `perfiles_trabajador` si `id_rol = 2`.

## Cómo probar

No hay suite de tests automatizada todavía. El flujo usado durante el desarrollo:

1. `npm run dev` (ejecuta `node server.js`; no hay recarga automática — reinicia manualmente tras cada cambio).
2. Postman/Insomnia/curl contra `http://localhost:<PORT>`, con un usuario de prueba registrado vía `/api/auth/registro` y su token.
3. Para validar sintaxis y rutas/validaciones sin tocar la base, se usó `node --check` por archivo + un script Node que levanta `app.js` en un puerto efímero y hace `fetch` a los endpoints verificando el código HTTP esperado (sin mocks de BD: los casos que llegan a MySQL se validan aparte, contra la base real, limpiando los datos de prueba al final).

## Pendientes conocidos (ver también README.md)

- Endpoints de editar perfil propio, eliminar cuenta, cambiar/recuperar contraseña.
- Endpoints de portafolio (tabla `imagenes_portafolio` ya existe, sin CRUD expuesto).
- Notificaciones push con la app cerrada: en Android requieren FCM (`firebase-admin` solo como canal de envío, usando los tokens de `dispositivos_notificacion`).
- Chat en tiempo real con WebSockets (Socket.IO) en lugar de consulta periódica.
- Almacenamiento de imágenes en un servicio externo (S3/R2) para producción, y limpieza de archivos de `archivos` que nunca se usaron.
- Endpoint para actualizar la foto de perfil (falta columna/procedimiento en `usuarios`).
- `servicioModel.buscarServicios` no pagina, no filtra por texto libre y no puede excluir bloqueados (la ruta es pública). Desde la migración 002 ya devuelve calificación y disponibilidad, excluye inactivos y no envía el teléfono.
- Endurecimiento pendiente: `helmet`, rate limiting en auth, CORS restringido a los orígenes reales, rechazar login de usuarios con `activo = FALSE`, y que el registro valide `id_rol` contra los roles permitidos en vez de aceptar cualquier valor.
- Zona horaria: la agenda (`GET /api/agenda`) ya devuelve `fecha_inicio`/`fecha_fin` como texto `YYYY-MM-DD HH:mm:ss` (hora de pared, sin conversión a UTC). El resto de rutas sigue devolviendo los `DATETIME` como `Date` de `mysql2` (ISO en UTC); revisar cuando se conecten solicitudes, chat y notificaciones.
- El esquema completo ya está consolidado en `sql/schema_completo.sql`; los cambios nuevos se agregan como migraciones numeradas y hay que regenerar ese archivo.
