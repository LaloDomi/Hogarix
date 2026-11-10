import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/colors.dart';

/// Mensaje centrado para listas vacías.
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? detalle;
  final Widget? accion;
  final Color colorTexto;

  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.detalle,
    this.accion,
    this.colorTexto = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: C.card, shape: BoxShape.circle),
            child: Icon(icono, size: 34, color: C.light),
          ),
          const SizedBox(height: 14),
          Text(titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colorTexto, fontSize: 16, fontWeight: FontWeight.w700)),
          if (detalle != null) ...[
            const SizedBox(height: 6),
            Text(detalle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: C.muted, fontSize: 13, height: 1.4)),
          ],
          if (accion != null) ...[const SizedBox(height: 14), accion!],
        ],
      ),
    );
  }
}

/// Mensaje de error con botón para reintentar.
class EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const EstadoError({super.key, required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, color: C.muted, size: 36),
          const SizedBox(height: 10),
          Text(mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: C.muted, fontSize: 14)),
          const SizedBox(height: 8),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

/// Muestra un aviso breve abajo de la pantalla.
void mostrarAviso(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensaje)));
}
