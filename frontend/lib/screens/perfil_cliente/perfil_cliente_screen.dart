import 'package:flutter/material.dart';
import 'package:manocerca/core/models/resena.dart';
import 'package:manocerca/core/models/solicitud.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/core/widgets/rating.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/editar_perfil/editar_perfil_screen.dart';
import 'package:manocerca/screens/main_shell/shell_controller.dart';
import 'package:manocerca/screens/perfil_cliente/favoritos_screen.dart';
import 'package:manocerca/screens/perfil_trabajador/widgets/tab_resenas.dart';
import 'package:manocerca/screens/reviews/reviews_screen.dart';
import 'package:manocerca/screens/ubicacion/ubicacion_sheet.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/resena_service.dart';
import 'package:manocerca/services/solicitud_service.dart';
import 'package:provider/provider.dart';

/// Pestaña "Perfil" del cliente: su calificación (los trabajadores también lo
/// califican, como en Uber), sus números y accesos rápidos.
class PerfilClienteScreen extends StatefulWidget {
  const PerfilClienteScreen({super.key});

  @override
  State<PerfilClienteScreen> createState() => _PerfilClienteScreenState();
}

class _PerfilClienteScreenState extends State<PerfilClienteScreen> {
  List<Resena>? _resenas;
  List<Solicitud>? _solicitudes;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final api = context.read<ApiClient>();
    final id = context.read<AuthProvider>().usuario?.id;
    if (id == null) return;
    await Future.wait([
      _cargarResenas(api, id),
      _cargarSolicitudes(api),
    ]);
  }

  // Si algo falla se muestra vacío: nunca se queda cargando para siempre.
  Future<void> _cargarResenas(ApiClient api, int id) async {
    List<Resena> r;
    try {
      r = await ResenaService(api).deUsuario(id);
    } catch (_) {
      r = const [];
    }
    if (mounted) setState(() => _resenas = r);
  }

  Future<void> _cargarSolicitudes(ApiClient api) async {
    List<Solicitud> s;
    try {
      s = await SolicitudService(api).listar();
    } catch (_) {
      s = const [];
    }
    if (mounted) setState(() => _solicitudes = s);
  }

  Widget _numero(String valor, String etiqueta) => Expanded(
        child: Column(
          children: [
            Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(etiqueta, style: const TextStyle(color: C.muted, fontSize: 12)),
          ],
        ),
      );

  Widget _opcion(IconData icono, String titulo, String detalle, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDeco(),
            child: Row(
              children: [
                Icon(icono, color: C.light),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(detalle, style: const TextStyle(color: C.muted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: C.muted),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    if (usuario == null) return const SizedBox.shrink();
    final resumen = ResumenResenas.de(_resenas ?? const []);
    final solicitudes = _solicitudes ?? const <Solicitud>[];
    final completadas = solicitudes.where((s) => s.completada).length;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Cabecera con el mismo lenguaje visual que el perfil del trabajador.
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E4FA8), C.bg],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Avatar(
                  name: usuario.nombreCompleto,
                  foto: urlFoto(context, usuario.fotoPerfil),
                  size: 104,
                  borde: C.bg,
                ),
                const SizedBox(height: 10),
                RatingChip(rating: resumen.promedio),
                const SizedBox(height: 10),
                Text(usuario.nombreCompleto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(usuario.contacto, style: const TextStyle(color: C.muted, fontSize: 13)),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => editarUbicacion(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: C.primary),
                        const SizedBox(width: 4),
                        Text(usuario.ubicacionTexto ?? 'Agregar ubicación',
                            style: TextStyle(
                                color: usuario.tieneUbicacion ? Colors.white : C.light,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: C.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Editar perfil'),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: cardDeco(16),
            child: Row(
              children: [
                _numero('${solicitudes.length}', 'Solicitudes'),
                _numero('$completadas', 'Completadas'),
                _numero('${resumen.total}', 'Reseñas'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Cómo te califican los profesionales',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text(
                  'Al terminar cada trabajo, el profesional también te califica. '
                  'Una buena calificación te ayuda a conseguir respuesta más rápido.',
                  style: TextStyle(color: C.muted, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                if (_resenas == null)
                  const Center(child: CircularProgressIndicator())
                else if (_resenas!.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: cardDeco(14),
                    child: const Row(
                      children: [
                        Icon(Icons.star_outline_rounded, color: C.star),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Aún no tienes calificaciones.',
                              style: TextStyle(color: C.muted)),
                        ),
                      ],
                    ),
                  )
                else ...[
                  ResumenEstrellas(resumen: resumen),
                  const SizedBox(height: 12),
                  for (final r in _resenas!.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TarjetaResena(resena: r),
                    ),
                  if (_resenas!.length > 3)
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewsScreen(
                              idUsuario: usuario.id, nombre: usuario.nombreCompleto),
                        ),
                      ),
                      child: Text('Ver las ${_resenas!.length} reseñas'),
                    ),
                ],
                const SizedBox(height: 18),
                _opcion(
                  Icons.assignment_outlined,
                  'Mis solicitudes',
                  'Sigue tus servicios y califica los terminados',
                  () => context.read<ShellController>().ir(3),
                ),
                _opcion(
                  Icons.favorite_border,
                  'Mis favoritos',
                  'Profesionales que guardaste',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritosScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                OutlineButtonX(
                  text: 'Cerrar sesión',
                  icon: Icons.logout,
                  onTap: () => context.read<AuthProvider>().cerrarSesion(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
