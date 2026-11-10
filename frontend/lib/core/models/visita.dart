import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/core/utils/json.dart';

class EstadoVisita {
  static const propuesta = 'Propuesta';
  static const confirmada = 'Confirmada';
  static const cancelada = 'Cancelada';
  static const realizada = 'Realizada';
}

/// Visita de trabajo agendada sobre una solicitud. La ven en su calendario
/// tanto el cliente como el trabajador.
class Visita {
  final int id;
  final int idSolicitud;
  final DateTime inicio;
  final DateTime fin;
  final String? direccion;
  final String? notas;
  final String estado;
  final bool propuestaPorMi;
  final String categoria;
  final int idCliente;
  final String nombreCliente;
  final String? fotoCliente;
  final int idTrabajador;
  final String nombreTrabajador;
  final String? fotoTrabajador;

  const Visita({
    required this.id,
    required this.idSolicitud,
    required this.inicio,
    required this.fin,
    required this.estado,
    required this.categoria,
    required this.idCliente,
    required this.nombreCliente,
    required this.idTrabajador,
    required this.nombreTrabajador,
    this.direccion,
    this.notas,
    this.propuestaPorMi = false,
    this.fotoCliente,
    this.fotoTrabajador,
  });

  bool ocurreEn(DateTime dia) {
    final desde = soloDia(dia);
    final hasta = DateTime(dia.year, dia.month, dia.day + 1);
    return inicio.isBefore(hasta) && fin.isAfter(desde);
  }

  String get rangoTexto => mismoDia(inicio, fin)
      ? '${horaTexto(inicio)} – ${horaTexto(fin)}'
      : '${diaMesAbreviado(inicio)} ${horaTexto(inicio)} – ${diaMesAbreviado(fin)} ${horaTexto(fin)}';

  /// Le toca a esta persona confirmarla.
  bool get esperaMiConfirmacion => estado == EstadoVisita.propuesta && !propuestaPorMi;

  bool get activa => estado == EstadoVisita.propuesta || estado == EstadoVisita.confirmada;

  ({int id, String nombre, String? foto}) contraparte(int idYo) => idYo == idCliente
      ? (id: idTrabajador, nombre: nombreTrabajador, foto: fotoTrabajador)
      : (id: idCliente, nombre: nombreCliente, foto: fotoCliente);

  factory Visita.fromJson(Map<String, dynamic> json) => Visita(
        id: enteroJson(json['id_visita']),
        idSolicitud: enteroJson(json['id_solicitud']),
        inicio: parseFechaSql('${json['fecha_inicio']}'),
        fin: parseFechaSql('${json['fecha_fin']}'),
        direccion: json['direccion'] as String?,
        notas: json['notas'] as String?,
        estado: (json['estado'] as String?) ?? EstadoVisita.propuesta,
        propuestaPorMi: boolJson(json['propuesta_por_mi']),
        categoria: (json['nombre_categoria'] as String?) ?? '',
        idCliente: enteroJson(json['id_cliente']),
        nombreCliente:
            '${json['nombre_cliente'] ?? ''} ${json['apellido_cliente'] ?? ''}'.trim(),
        fotoCliente: json['foto_cliente'] as String?,
        idTrabajador: enteroJson(json['id_trabajador']),
        nombreTrabajador:
            '${json['nombre_trabajador'] ?? ''} ${json['apellido_trabajador'] ?? ''}'.trim(),
        fotoTrabajador: json['foto_trabajador'] as String?,
      );
}
