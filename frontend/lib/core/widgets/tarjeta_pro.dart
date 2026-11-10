import 'package:flutter/material.dart';
import 'package:manocerca/core/models/pro.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/core/widgets/stars.dart';

/// Tarjeta de un profesional en las listas de resultados.
class TarjetaPro extends StatelessWidget {
  final Pro pro;
  final VoidCallback onTap;
  final bool mostrarCategoria;

  const TarjetaPro({
    super.key,
    required this.pro,
    required this.onTap,
    this.mostrarCategoria = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = pro;
    final descripcion = p.descripcion?.trim() ?? '';
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: cardDeco(),
        child: Row(
          children: [
            Avatar(name: p.name, foto: urlFoto(context, p.fotoPerfil), size: 68),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (mostrarCategoria && p.categoria != null)
                    Text(p.categoria!,
                        style: const TextStyle(color: C.light, fontSize: 12)),
                  if (p.ubicacion != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: C.muted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(p.ubicacion!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: C.muted, fontSize: 12)),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  if (p.rating != null)
                    Row(
                      children: [
                        Stars(rating: p.rating!),
                        const SizedBox(width: 6),
                        Text('${p.rating!.toStringAsFixed(1)} (${p.reviews})',
                            style: const TextStyle(color: C.muted, fontSize: 12)),
                      ],
                    )
                  else
                    const Text('Sin reseñas aún',
                        style: TextStyle(color: C.muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(p.precioTexto,
                      style: const TextStyle(
                          color: C.light, fontSize: 13, fontWeight: FontWeight.w600)),
                  if (descripcion.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: C.muted, fontSize: 12)),
                  ],
                  if (p.availability != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 9, color: p.disponible ? C.green : C.star),
                        const SizedBox(width: 5),
                        Text(p.availability!,
                            style: TextStyle(
                                color: p.disponible ? C.green : C.star, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: C.muted),
          ],
        ),
      ),
    );
  }
}
