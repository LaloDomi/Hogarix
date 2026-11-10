import 'package:flutter/material.dart';
import 'package:manocerca/core/models/publicacion.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/screens/perfil_trabajador/perfil_trabajador_screen.dart';
import 'package:manocerca/screens/publicaciones/publicacion_detalle_screen.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/publicacion_service.dart';
import 'package:provider/provider.dart';

/// Carrusel "Trabajos recientes" del Inicio del cliente: lo último que
/// publicaron los profesionales. Si no hay o falla, no ocupa espacio.
class TrabajosRecientes extends StatefulWidget {
  const TrabajosRecientes({super.key});

  @override
  State<TrabajosRecientes> createState() => _TrabajosRecientesState();
}

class _TrabajosRecientesState extends State<TrabajosRecientes> {
  List<Publicacion> _publicaciones = const [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await PublicacionService(context.read<ApiClient>()).listar(limite: 10);
      if (mounted) {
        setState(() => _publicaciones = lista.where((p) => p.portada != null).toList());
      }
    } catch (_) {
      // Sección opcional: si falla simplemente no se muestra.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_publicaciones.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        const Text('Trabajos recientes',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Lo último que han hecho los profesionales',
            style: TextStyle(color: C.muted, fontSize: 13)),
        const SizedBox(height: 12),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _publicaciones.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final p = _publicaciones[i];
              return SizedBox(
                width: 170,
                child: Material(
                  color: C.cardLight,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublicacionDetalleScreen(publicacion: p),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ImagenRed(ruta: p.portada, height: 112, width: 170),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                          child: Text(p.titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: C.textDark, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PerfilTrabajadorScreen(idUsuario: p.idAutor),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                            child: Row(
                              children: [
                                const Icon(Icons.handyman, size: 12, color: C.textDarkMuted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(p.nombreAutor,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: C.textDarkMuted, fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
