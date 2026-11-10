import 'package:flutter/material.dart';
import 'package:manocerca/core/models/solicitud.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/screens/calificar/calificar_screen.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/solicitud_service.dart';
import 'package:provider/provider.dart';

/// Cambia el estado de una solicitud pidiendo confirmación cuando hace falta.
/// Si el trabajo se completa, abre de inmediato la calificación (como Uber).
/// Devuelve `true` si algo cambió.
Future<bool> cambiarEstadoSolicitud(
  BuildContext context,
  Solicitud s,
  String estado,
  int idYo,
) async {
  final textos = switch (estado) {
    EstadoSolicitud.rechazado => (
        'Rechazar solicitud',
        'Se le avisará al cliente que no puedes tomar este trabajo.',
        'Rechazar',
      ),
    EstadoSolicitud.cancelado => (
        'Cancelar solicitud',
        'Se le avisará a la otra persona. Esta acción no se puede deshacer.',
        'Cancelar solicitud',
      ),
    EstadoSolicitud.completado => (
        'Marcar como completado',
        '¿El trabajo ya quedó terminado? Después podrán calificarse mutuamente.',
        'Completado',
      ),
    _ => null,
  };

  if (textos != null) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(textos.$1),
        content: Text(textos.$2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              textos.$3,
              style: TextStyle(
                  color: estado == EstadoSolicitud.completado ? C.green : C.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return false;
  }

  try {
    await SolicitudService(context.read<ApiClient>()).cambiarEstado(s.id, estado);
  } on ApiException catch (e) {
    if (context.mounted) mostrarAviso(context, e.mensaje);
    return false;
  }
  if (!context.mounted) return true;

  mostrarAviso(context, switch (estado) {
    EstadoSolicitud.aceptado => 'Solicitud aceptada',
    EstadoSolicitud.rechazado => 'Solicitud rechazada',
    EstadoSolicitud.completado => 'Trabajo completado',
    _ => 'Solicitud cancelada',
  });

  if (estado == EstadoSolicitud.completado) {
    await abrirCalificacion(context, s.copyWith(estado: estado), idYo);
  }
  return true;
}

/// Abre la pantalla de calificación. Devuelve `true` si se envió.
Future<bool> abrirCalificacion(BuildContext context, Solicitud s, int idYo,
    {int estrellas = 0}) async {
  final enviado = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => CalificarScreen(solicitud: s, idYo: idYo, estrellasIniciales: estrellas),
    ),
  );
  return enviado ?? false;
}
