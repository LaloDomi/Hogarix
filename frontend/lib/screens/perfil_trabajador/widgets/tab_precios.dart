import 'package:flutter/material.dart';
import 'package:manocerca/core/models/mi_servicio.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/categoria_icono.dart';
import 'package:manocerca/core/widgets/estados.dart';

/// Pestaña "Rango de precios": del más barato al más caro y el detalle de
/// cada servicio que ofrece.
class TabPrecios extends StatelessWidget {
  final PerfilTrabajador perfil;
  final bool esPropio;
  final VoidCallback onAdministrar;

  const TabPrecios({
    super.key,
    required this.perfil,
    required this.esPropio,
    required this.onAdministrar,
  });

  static String _monto(double v) =>
      '\$${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    if (perfil.servicios.isEmpty) {
      return EstadoVacio(
        icono: Icons.sell_outlined,
        titulo: esPropio ? 'Aún no registras servicios' : 'Sin servicios registrados',
        detalle: esPropio ? 'Agrega lo que ofreces y cuánto cobras.' : null,
        accion: esPropio
            ? FilledButton.icon(
                onPressed: onAdministrar,
                icon: const Icon(Icons.add),
                label: const Text('Agregar servicio'),
              )
            : null,
      );
    }
    final rango = perfil.rangoPrecios;
    final servicios = [...perfil.servicios]
      ..sort((a, b) => (a.precioBase ?? double.infinity).compareTo(b.precioBase ?? double.infinity));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E4FA8), Color(0xFF14284B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.payments_outlined, color: Colors.white, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rango de precios',
                        style: TextStyle(color: Color(0xFFD0DBF0), fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      rango == null
                          ? 'Precio a convenir'
                          : rango.min == rango.max
                              ? _monto(rango.min)
                              : '${_monto(rango.min)} – ${_monto(rango.max)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final s in servicios)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: cardDeco(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: C.bg2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconoDeCategoria(s.categoria), color: C.light),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.categoria,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      if ((s.descripcion ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(s.descripcion!.trim(),
                            style: const TextStyle(color: C.muted, fontSize: 12, height: 1.35)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(s.precioTexto,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: C.light, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        if (esPropio)
          TextButton.icon(
            onPressed: onAdministrar,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Administrar servicios y precios'),
          ),
      ],
    );
  }
}
