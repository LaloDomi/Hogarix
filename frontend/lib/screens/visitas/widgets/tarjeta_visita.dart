import 'package:flutter/material.dart';
import 'package:manocerca/core/models/visita.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/screens/chat/chat_screen.dart';
import 'package:manocerca/screens/visitas/agendar_visita_screen.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/visita_service.dart';
import 'package:provider/provider.dart';

({Color color, String texto}) _estilo(Visita v) => switch (v.estado) {
      EstadoVisita.confirmada => (color: C.green, texto: 'Confirmada'),
      EstadoVisita.realizada => (color: C.muted, texto: 'Realizada'),
      _ => (
          color: C.star,
          texto: v.propuestaPorMi ? 'Esperando confirmación' : 'Por confirmar'
        ),
    };

/// Visita en el calendario, con las acciones que tocan según quién la propuso.
/// [alCambiar] se llama cuando algo cambió para recargar el calendario.
class TarjetaVisita extends StatelessWidget {
  final Visita visita;
  final int idYo;
  final bool soyTrabajador;
  final VoidCallback alCambiar;

  const TarjetaVisita({
    super.key,
    required this.visita,
    required this.idYo,
    required this.soyTrabajador,
    required this.alCambiar,
  });

  Future<void> _estado(BuildContext context, String estado) async {
    if (estado == EstadoVisita.cancelada) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancelar visita'),
          content: const Text('Se le avisará a la otra persona.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancelar visita', style: TextStyle(color: C.red)),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
    }
    try {
      await VisitaService(context.read<ApiClient>()).cambiarEstado(visita.id, estado);
      if (!context.mounted) return;
      mostrarAviso(context, switch (estado) {
        EstadoVisita.confirmada => 'Visita confirmada',
        EstadoVisita.realizada => 'Visita marcada como realizada',
        _ => 'Visita cancelada',
      });
      alCambiar();
    } on ApiException catch (e) {
      if (context.mounted) mostrarAviso(context, e.mensaje);
    }
  }

  Future<void> _reprogramar(BuildContext context) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AgendarVisitaScreen(visita: visita)),
    );
    if (ok == true) alCambiar();
  }

  @override
  Widget build(BuildContext context) {
    final v = visita;
    final otro = v.contraparte(idYo);
    final e = _estilo(v);
    final notas = (v.notas ?? '').trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: e.color.withAlpha(110)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: e.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Avatar(name: otro.nombre, foto: urlFoto(context, otro.foto), size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Visita · ${v.categoria}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('${v.rangoTexto} · ${otro.nombre}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: C.light, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opciones de la visita',
                color: C.card,
                onSelected: (a) {
                  switch (a) {
                    case 'mensaje':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                              idOtroUsuario: otro.id, nombre: otro.nombre, foto: otro.foto),
                        ),
                      );
                    case 'reprogramar':
                      _reprogramar(context);
                    case 'realizada':
                      _estado(context, EstadoVisita.realizada);
                    case 'cancelar':
                      _estado(context, EstadoVisita.cancelada);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'mensaje', child: Text('Enviar mensaje')),
                  if (v.activa)
                    const PopupMenuItem(value: 'reprogramar', child: Text('Cambiar horario')),
                  if (soyTrabajador && v.estado == EstadoVisita.confirmada)
                    const PopupMenuItem(value: 'realizada', child: Text('Marcar realizada')),
                  if (v.activa)
                    const PopupMenuItem(value: 'cancelar', child: Text('Cancelar visita')),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 10, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 9, color: e.color),
                    const SizedBox(width: 6),
                    Text(e.texto, style: TextStyle(color: e.color, fontSize: 12)),
                  ],
                ),
                if ((v.direccion ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: C.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(v.direccion!,
                            style: const TextStyle(color: C.muted, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
                if (notas.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(notas,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: C.muted, fontSize: 12)),
                ],
                if (v.esperaMiConfirmacion) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _reprogramar(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: C.border),
                          ),
                          child: const Text('Otro horario'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _estado(context, EstadoVisita.confirmada),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                          child: const Text('Confirmar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
