import 'package:flutter/material.dart';
import 'package:manocerca/core/models/resena.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/core/widgets/stars.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/ia_service.dart';
import 'package:provider/provider.dart';

/// Pestaña "Reseñas": resumen de estrellas y las reseñas más recientes.
class TabResenas extends StatelessWidget {
  final List<Resena>? resenas;
  final String? error;
  final VoidCallback onReintentar;
  final VoidCallback? onVerTodas;
  final int maximo;

  /// Si se pasa, aparece el resumen con IA de las reseñas de este trabajador.
  final int? idTrabajador;

  const TabResenas({
    super.key,
    required this.resenas,
    required this.error,
    required this.onReintentar,
    this.onVerTodas,
    this.maximo = 5,
    this.idTrabajador,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) return EstadoError(mensaje: error!, onReintentar: onReintentar);
    final lista = resenas;
    if (lista == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (lista.isEmpty) {
      return const EstadoVacio(
        icono: Icons.star_outline_rounded,
        titulo: 'Sin reseñas aún',
        detalle: 'Las reseñas aparecen cuando se completa un trabajo.',
      );
    }
    final visibles = lista.take(maximo).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResumenEstrellas(resumen: ResumenResenas.de(lista)),
        const SizedBox(height: 14),
        if (idTrabajador != null &&
            lista.where((r) => (r.comentario ?? '').trim().length >= 3).length >=
                ResumenResenasIA.minimo) ...[
          ResumenResenasIA(idTrabajador: idTrabajador!),
          const SizedBox(height: 14),
        ],
        for (final r in visibles)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TarjetaResena(resena: r),
          ),
        if (lista.length > visibles.length && onVerTodas != null)
          TextButton(
            onPressed: onVerTodas,
            child: Text('Ver las ${lista.length} reseñas'),
          ),
      ],
    );
  }
}

/// "Lo que dicen los clientes": resumen de las reseñas hecho con IA.
/// Se genera solo cuando la persona lo pide, para cuidar la cuota.
class ResumenResenasIA extends StatefulWidget {
  /// Reseñas con comentario necesarias (igual que en el backend).
  static const minimo = 3;

  final int idTrabajador;
  const ResumenResenasIA({super.key, required this.idTrabajador});

  @override
  State<ResumenResenasIA> createState() => _ResumenResenasIAState();
}

class _ResumenResenasIAState extends State<ResumenResenasIA> {
  bool _cargando = false;
  String? _texto;
  String? _error;

  Future<void> _generar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await IaService(context.read<ApiClient>()).resumenResenas(widget.idTrabajador);
      if (!mounted) return;
      setState(() => _texto = r.resumen ?? r.motivo);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo hacer el resumen. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = _texto;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDeco(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: C.light, size: 18),
              SizedBox(width: 8),
              Text('Lo que dicen los clientes',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          if (texto != null) ...[
            Text(texto, style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 6),
            const Text('Resumen hecho con IA a partir de las reseñas.',
                style: TextStyle(color: C.muted, fontSize: 11)),
          ] else if (_cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            const Text('Un resumen corto de todas sus reseñas.',
                style: TextStyle(color: C.muted, fontSize: 13)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _generar,
                icon: const Icon(Icons.auto_awesome, size: 16, color: C.light),
                label: const Text('Ver resumen', style: TextStyle(color: C.light)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Promedio grande + barras por número de estrellas.
class ResumenEstrellas extends StatelessWidget {
  final ResumenResenas resumen;
  const ResumenEstrellas({super.key, required this.resumen});

  @override
  Widget build(BuildContext context) {
    final total = resumen.total == 0 ? 1 : resumen.total;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(resumen.promedio?.toStringAsFixed(1) ?? '–',
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
            Stars(rating: resumen.promedio ?? 0.0, size: 16),
            const SizedBox(height: 4),
            Text(resumen.total == 1 ? '1 reseña' : '${resumen.total} reseñas',
                style: const TextStyle(color: C.muted, fontSize: 12)),
          ],
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            children: [
              for (int i = 0; i < 5; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        child: Text('${5 - i}',
                            style: const TextStyle(fontSize: 12, color: C.muted)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: resumen.conteo[i] / total,
                            minHeight: 7,
                            backgroundColor: C.card,
                            valueColor: const AlwaysStoppedAnimation(C.star),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarjeta clara de una reseña (diseño Figma).
class TarjetaResena extends StatelessWidget {
  final Resena resena;
  const TarjetaResena({super.key, required this.resena});

  @override
  Widget build(BuildContext context) {
    final r = resena;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: C.cardLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(name: r.nombreAutor, foto: urlFoto(context, r.fotoAutor), size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(r.nombreAutor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: C.textDark, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    const Icon(Icons.star_rounded, color: C.star, size: 16),
                    const SizedBox(width: 2),
                    Text('${r.calificacion}.0',
                        style: const TextStyle(
                            color: C.textDark, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                if (r.fecha != null)
                  Text(haceCuanto(r.fecha!),
                      style: const TextStyle(color: C.textDarkMuted, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  (r.comentario ?? '').trim().isEmpty
                      ? 'Calificó sin comentario.'
                      : r.comentario!.trim(),
                  style: const TextStyle(color: C.textDarkMuted, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
