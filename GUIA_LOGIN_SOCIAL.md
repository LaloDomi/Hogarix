# Inicio de sesión con Google y Facebook

Los botones oficiales de Google y Facebook siguen fuera de la app (necesitan
Google Cloud / Facebook Developers).

En su lugar existe **"Continuar con Gmail"**: la persona escribe su Gmail (o
cualquier correo), le llega un código de 6 dígitos y con eso entra o crea su
cuenta. No necesita Google Cloud. Configuración en `GUIA_CORREO_E_IA.md`.

El backend conserva las rutas POST /api/auth/google y /api/auth/facebook por si más adelante se vuelve a activar.
