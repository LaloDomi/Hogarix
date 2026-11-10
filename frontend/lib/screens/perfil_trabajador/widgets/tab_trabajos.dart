import 'package:flutter/material.dart';
import 'package:manocerca/core/models/publicacion.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';

/// Pestaña "Trabajos": publicaciones del trabajador en tarjetas claras con
/// la foto a la izquierda (diseño Figma).
class TabTrabajos extends StatelessWidget {
  final List<Publicacion>? publicaciones;
  final String? error;
  final bool esPropio;
  final VoidCallback onReintentar;
  final VoidCallback onPublicar;
  final ValueChanged<Publicacion> onAbrir;

  const TabTrabajos({
    super.key,
    required this.publicaciones,
    required this.error,
    required this.esPropio,
    required this.onReintentar,
    required this.onPublicar,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) return EstadoError(mensaje: error!, onReintentar: onReintentar);
    final lista = publicaciones;
    if (lista == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (lista.isEmpty) {
      return esPropio
          ? EstadoVacio(
              icono: Icons.add_a_photo_outlined,
              titulo: 'Muestra tu trabajo',
              detalle: 'Publica fotos de los trabajos que has hecho. '
                  'Los clientes confían más en perfiles con fotos.',
              accion: FilledButton.icon(
                onPressed: onPublicar,
                icon: const Icon(Icons.add),
                label: const Text('Publicar trabajo'),
              ),
            )
          : const EstadoVacio(
              icono: Icons.photo_library_outlined,
              titulo: 'Aún no hay trabajos publicados',
            );
    }
    return Column(
      children: [
        for (final p in lista)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TarjetaTrabajo(publicacion: p, onTap: () => onAbrir(p)),
          ),
      ],
    );
  }
}

class TarjetaTrabajo extends StatelessWidget {
  final Publicacion publicacion;
  final VoidCallback onTap;
  const TarjetaTrabajo({super.key, required this.publicacion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = publicacion;
    return Material(
      color: C.cardLight,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    ImagenRed(ruta: p.portada, width: 120, height: 96),
                    if (p.imagenes.length > 1)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xAA000000),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library, size: 11, color: Colors.white),
                              const SizedBox(width: 3),
                              Text('${p.imagenes.length}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: C.textDark, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(p.contenido,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: C.textDarkMuted, fontSize: 12, height: 1.35)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 13, color: Colors.redAccent),
                        const SizedBox(width: 3),
                        Text('${p.totalLikes}',
                            style: const TextStyle(color: C.textDarkMuted, fontSize: 11)),
                        const SizedBox(width: 10),
                        const Icon(Icons.mode_comment_outlined,
                            size: 13, color: C.textDarkMuted),
                        const SizedBox(width: 3),
                        Text('${p.totalComentarios}',
                            style: const TextStyle(color: C.textDarkMuted, fontSize: 11)),
                        const Spacer(),
                        if (p.fecha != null)
                          Text(haceCuanto(p.fecha!),
                              style: const TextStyle(color: C.textDarkMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
