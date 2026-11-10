import 'package:flutter/material.dart';
import 'package:manocerca/core/models/solicitud.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';

/// Color e icono de cada estado.
({Color color, IconData icono}) estiloEstado(String estado) => switch (estado) {
      EstadoSolicitud.pendiente => (color: C.star, icono: Icons.schedule),
      EstadoSolicitud.aceptado => (color: C.light, icono: Icons.handshake_outlined),
      EstadoSolicitud.completado => (color: C.green, icono: Icons.check_circle_outline),
      EstadoSolicitud.rechazado => (color: C.red, icono: Icons.block),
      _ => (color: C.muted, icono: Icons.cancel_outlined),
    };

class EtiquetaEstado extends StatelessWidget {
  final String estado;
  const EtiquetaEstado({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final e = estiloEstado(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: e.color.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: e.color.withAlpha(140)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(e.icono, size: 12, color: e.color),
          const SizedBox(width: 4),
          Text(estado, style: TextStyle(color: e.color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Tarjeta de una solicitud con las acciones que tocan según el rol y el estado.
class SolicitudCard extends StatelessWidget {
  final Solicitud solicitud;
  final int idYo;
  final bool soyTrabajador;
  final void Function(String estado) onCambiarEstado;
  final VoidCallback onCalificar;
  final VoidCallback? onAbrirPerfil;
  final VoidCallback? onAgendar;
  final VoidCallback? onMensaje;

  const SolicitudCard({
    super.key,
    required this.solicitud,
    required this.idYo,
    required this.soyTrabajador,
    required this.onCambiarEstado,
    required this.onCalificar,
    this.onAbrirPerfil,
    this.onAgendar,
    this.onMensaje,
  });

  List<Widget> _acciones() {
    final s = solicitud;
    Widget boton(String texto, VoidCallback onTap, {bool principal = false, Color? color}) =>
        Expanded(
          child: principal
              ? FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: color ?? C.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(texto),
                )
              : OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color ?? Colors.white,
                    side: BorderSide(color: color ?? C.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(texto),
                ),
        );

    switch (s.estado) {
      case EstadoSolicitud.pendiente:
        return soyTrabajador
            ? [
                boton('Rechazar', () => onCambiarEstado(EstadoSolicitud.rechazado), color: C.red),
                const SizedBox(width: 10),
                boton('Aceptar', () => onCambiarEstado(EstadoSolicitud.aceptado), principal: true),
              ]
            : [boton('Cancelar solicitud', () => onCambiarEstado(EstadoSolicitud.cancelado))];
      case EstadoSolicitud.aceptado:
        return [
          boton('Cancelar', () => onCambiarEstado(EstadoSolicitud.cancelado)),
          if (soyTrabajador) ...[
            const SizedBox(width: 10),
            boton('Marcar completado', () => onCambiarEstado(EstadoSolicitud.completado),
                principal: true, color: const Color(0xFF16A34A)),
          ],
        ];
      case EstadoSolicitud.completado:
        return s.yaCalifique
            ? const [
                Icon(Icons.verified, color: C.green, size: 18),
                SizedBox(width: 6),
                Text('Ya calificaste este trabajo',
                    style: TextStyle(color: C.muted, fontSize: 13)),
              ]
            : [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCalificar,
                    style: FilledButton.styleFrom(
                      backgroundColor: C.star,
                      foregroundColor: C.textDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.star_rounded),
                    label: Text(soyTrabajador ? 'Calificar al cliente' : 'Calificar servicio'),
                  ),
                ),
              ];
      default:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = solicitud;
    final otro = s.contraparte(idYo);
    final acciones = _acciones();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDeco(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onAbrirPerfil,
                child: Avatar(name: otro.nombre, foto: urlFoto(context, otro.foto), size: 46),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(otro.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      soyTrabajador ? 'Cliente · ${s.categoria}' : s.categoria,
                      style: const TextStyle(color: C.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (onMensaje != null)
                IconButton(
                  tooltip: 'Enviar mensaje',
                  visualDensity: VisualDensity.compact,
                  onPressed: onMensaje,
                  icon: const Icon(Icons.chat_bubble_outline, size: 20, color: C.light),
                ),
              EtiquetaEstado(estado: s.estado),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 15, color: C.light),
              const SizedBox(width: 6),
              Text(s.montoTexto, style: const TextStyle(fontSize: 13)),
              const Spacer(),
              if (s.fecha != null)
                Text(haceCuanto(s.fecha!), style: const TextStyle(color: C.muted, fontSize: 12)),
            ],
          ),
          if (s.proximaVisita != null || (s.activa && onAgendar != null)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_available, size: 15, color: C.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.proximaVisita == null
                        ? 'Sin visita agendada'
                        : 'Visita: ${fechaCorta(s.proximaVisita!)} · ${horaTexto(s.proximaVisita!)}',
                    style: TextStyle(
                        color: s.proximaVisita == null ? C.muted : Colors.white, fontSize: 13),
                  ),
                ),
                if (s.activa && onAgendar != null)
                  TextButton(
                    onPressed: onAgendar,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: Text(s.proximaVisita == null ? 'Agendar visita' : 'Otra visita'),
                  ),
              ],
            ),
          ],
          if (acciones.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: acciones),
          ],
        ],
      ),
    );
  }
}
