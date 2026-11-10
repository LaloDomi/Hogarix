import 'package:flutter/material.dart';
import 'package:manocerca/core/models/solicitud.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/core/widgets/rating.dart';
import 'package:manocerca/screens/calificar/calificar_screen.dart';

/// Hoja inferior "¿Cómo te fue con …?" que aparece al abrir la app cuando hay
/// un trabajo completado sin calificar. Al tocar una estrella abre la
/// pantalla completa de calificación. Devuelve `true` si se calificó.
Future<bool> mostrarAvisoCalificacion(
    BuildContext context, Solicitud solicitud, int idYo) async {
  final otro = solicitud.contraparte(idYo);
  final estrellas = await showModalBottomSheet<int>(
    context: context,
    backgroundColor: C.bg2,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: C.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            Avatar(name: otro.nombre, foto: urlFoto(context, otro.foto), size: 64),
            const SizedBox(height: 12),
            Text('¿Cómo te fue con ${otro.nombre}?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Tu calificación ayuda a toda la comunidad · ${solicitud.categoria}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: C.muted, fontSize: 13)),
            const SizedBox(height: 14),
            SelectorEstrellas(valor: 0, onChanged: (v) => Navigator.pop(context, v)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Más tarde', style: TextStyle(color: C.muted)),
            ),
          ],
        ),
      ),
    ),
  );
  if (estrellas == null || !context.mounted) return false;
  final enviado = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => CalificarScreen(
        solicitud: solicitud,
        idYo: idYo,
        estrellasIniciales: estrellas,
      ),
    ),
  );
  return enviado ?? false;
}
