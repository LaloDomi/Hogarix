# Hogarix / ManoCerca (frontend Flutter)

App de profesionales de oficios cerca de ti. Se conecta al backend de `../backend`
(ver el README principal para levantarlo).

## Cómo correrlo

```bash
flutter pub get
flutter run -d chrome          # o un emulador Android
flutter test && flutter analyze
```

## Clientes y trabajadores ven apps distintas

Después de iniciar sesión, `MainShell` arma la barra inferior según el rol:

| Cliente | Trabajador |
|---|---|
| Inicio (buscador, categorías, trabajos recientes) | Inicio = panel (disponibilidad, números, solicitudes nuevas) |
| Buscar (texto + filtros) | Calendario (agenda) |
| Solicitudes (seguir y calificar) | Mensajes |
| Mensajes | Perfil (portada, trabajos, precios, reseñas y botón **+**) |
| Perfil (su calificación, favoritos, cerrar sesión) | Más (servicios, solicitudes, cerrar sesión) |

## Estructura

```
lib/
├── main.dart                     # Providers (ApiClient, sesión, categorías)
├── app.dart                      # MaterialApp + tema + ShellController
├── core/                         # Lo compartido
│   ├── config/                   # URL del backend
│   ├── theme/                    # colors.dart, app_theme.dart
│   ├── models/                   # pro, usuario, mi_servicio (perfil), publicacion,
│   │                             # resena, solicitud, filtros_busqueda…
│   ├── utils/                    # fechas, precio, json, texto (búsqueda sin acentos)
│   └── widgets/                  # avatar, estrellas, rating, imagen_red, estados, tarjeta_pro
├── providers/                    # auth_provider, categorias_provider
├── services/                     # Una clase por módulo del backend
│   ├── api_client.dart           # HTTP + subida de imágenes (multipart)
│   ├── publicacion_service.dart  # trabajos tipo Facebook: fotos, likes, comentarios
│   ├── resena_service.dart       # calificaciones en ambos sentidos
│   ├── solicitud_service.dart    # solicitudes de trabajo
│   └── favorito_service.dart …
└── screens/                      # Una carpeta por pantalla
    ├── welcome/ auth/            # Bienvenida, login y registro
    ├── main_shell/               # Barra inferior por rol + ShellController
    ├── home/                     # Inicio del cliente (+ widgets/trabajos_recientes)
    ├── buscar/                   # Búsqueda con filtros en tiempo real
    ├── pro_list/                 # Profesionales de una categoría
    ├── perfil_trabajador/        # Perfil del diseño (cabecera + 3 pestañas en widgets/)
    ├── publicaciones/            # Crear publicación y verla completa
    ├── editar_perfil/            # Descripción y disponibilidad del trabajador
    ├── perfil_cliente/           # Perfil del cliente y favoritos
    ├── panel/                    # Inicio del trabajador
    ├── mas/                      # Menú "Más" del trabajador
    ├── solicitudes/              # Lista, tarjeta y acciones de solicitudes
    ├── calificar/                # Calificación tipo Uber + aviso al abrir la app
    ├── reviews/                  # Todas las reseñas de una persona
    ├── request/ confirmed/       # Solicitar servicio y confirmación
    ├── servicios/ agenda/        # Mis servicios y calendario del trabajador
    └── messages/ chat/           # Mensajes (todavía con datos de ejemplo)
```

## Calificaciones (como Uber)

1. El cliente solicita un servicio; el trabajador lo acepta y al terminar lo marca como completado.
2. En ese momento se le pide al trabajador calificar al cliente.
3. Al cliente se le muestra un aviso "¿Cómo te fue con …?" la próxima vez que abre la app, y
   también tiene el botón **Calificar servicio** en Solicitudes.
4. Cada calificación lleva estrellas, etiquetas rápidas (Puntual, Buen trato…) y un comentario.

## Publicaciones de trabajos

En su perfil, el trabajador toca **+** para subir hasta 10 fotos con título y descripción.
Cada foto se sube a `POST /api/archivos` y luego se crea la publicación con sus rutas.
Los clientes las ven en el perfil y en "Trabajos recientes" del Inicio, pueden dar
"Me gusta" y comentar.
