# OficioLink

App móvil para conectar **clientes** con **trabajadores de oficios** (carpintería, plomería, herrería, etc.), con funciones de red social: publicaciones, reseñas, favoritos, solicitudes de trabajo y chat.

Este repositorio contiene las dos partes de la aplicación:

| Carpeta | Qué es | Tecnología |
|---|---|---|
| [`backend/`](backend/) | API REST: cuentas, servicios, publicaciones, solicitudes, reseñas, chat, notificaciones | Node.js, Express 5, MySQL 8 |
| [`frontend/`](frontend/) | App móvil | Flutter (paquete `manocerca`), Provider |

La documentación de cada parte está en su carpeta:
- [`backend/README.md`](backend/README.md) — funcionamiento explicado de forma sencilla.
- [`backend/README_TECNICO.md`](backend/README_TECNICO.md) — arquitectura, convenciones y endpoints.

## Cómo correrlo en local

### 1. Base de datos
Para una base nueva, un solo script crea todo (21 tablas, procedimientos, función y catálogos de roles y categorías):

```bash
mysql --comments -u root -p < backend/sql/schema_completo.sql
```

Después aplica, en orden:
1. **`backend/sql/003_ubicacion_perfil_visitas_social.sql`** (ubicación, perfil completo y visitas).
2. **`backend/sql/004_telefono_codigos.sql`** (cuentas con teléfono, restablecer contraseña y entrar con Gmail por código).
3. **`backend/sql/005_cambiar_contrasena.sql`** (cambiar la contraseña desde el perfil).

En MySQL Workbench: *File → Open SQL Script…* → el archivo → botón del rayo. Se pueden ejecutar varias veces sin problema.

Las migraciones `001_...` y `002_...` ya están incluidas en `schema_completo.sql`; sirven para actualizar una base existente sin recrearla.

El script no incluye datos de usuarios ni de la aplicación.

### 2. Backend
```bash
cd backend
cp .env.example .env     # completa DB_PASSWORD y JWT_SECRET (PORT=3001)
npm install
npm run dev              # http://localhost:3001
```

En Windows también puedes dar doble clic a **`iniciar_backend.bat`** (raíz del proyecto). Deja esa ventana abierta.
Para revisar que todo responde abre <http://localhost:3001/api/salud>: debe decir que el servidor y la base funcionan.

### 3. Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome    # o un emulador Android
```

O doble clic a **`iniciar_app.bat`**.

La app elige sola la URL del backend: `localhost:3001` en web y `10.0.2.2:3001` en el emulador de Android. Para un celular físico o producción:

```bash
flutter run --dart-define=API_URL=http://<IP-de-tu-PC>:3001
```

## Correos e inteligencia artificial
Restablecer contraseña, "Continuar con Gmail" y el asistente IA necesitan unas
variables más en el `.env` (o en *Environment* de Render). Paso a paso en
[`GUIA_CORREO_E_IA.md`](GUIA_CORREO_E_IA.md).

## Pruebas
```bash
cd frontend && flutter test && flutter analyze
```
