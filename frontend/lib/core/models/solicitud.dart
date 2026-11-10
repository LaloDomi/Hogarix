import 'package:manocerca/core/data/ubicaciones_mx.dart';
import 'package:manocerca/core/utils/json.dart';
import 'package:manocerca/core/utils/precio.dart';

/// Estados que maneja el backend.
class EstadoSolicitud {
  static const pendiente = 'Pendiente';
  static const aceptado = 'Aceptado';
  static const rechazado = 'Rechazado';
  static const completado = 'Completado';
  static const cancelado = 'Cancelado';

  static const todos = [pendiente, aceptado, completado, rechazado, cancelado];
}

/// Una solicitud de trabajo entre un cliente y un trabajador.
class Solicitud {
  final int id;
  final String estado;
  final String tipoPago;
  final double? monto;
  final DateTime? fecha;
  final int idCategoria;
  final String categoria;
  final int idCliente;
  final String nombreCliente;
  final String? fotoCliente;
  final int idTrabajador;
  final String nombreTrabajador;
  final String? fotoTrabajador;

  /// ¿El usuario de la sesión ya dejó su calificación?
  final bool yaCalifique;

  /// Siguiente visita propuesta o confirmada (si hay).
  final DateTime? proximaVisita;
  final String? estadoCliente;
  final String? municipioCliente;
  final String? coloniaCliente;

  const Solicitud({
    required this.id,
    required this.estado,
    required this.tipoPago,
    required this.idCategoria,
    required this.categoria,
    required this.idCliente,
    required this.nombreCliente,
    required this.idTrabajador,
    required this.nombreTrabajador,
    this.monto,
    this.fecha,
    this.fotoCliente,
    this.fotoTrabajador,
    this.yaCalifique = false,
    this.proximaVisita,
    this.estadoCliente,
    this.municipioCliente,
    this.coloniaCliente,
  });

  /// Se pueden agendar visitas mientras está pendiente o aceptada.
  bool get activa => estado == EstadoSolicitud.pendiente || estado == EstadoSolicitud.aceptado;

  /// "Col. Centro, Puebla, Pue." — dirección sugerida para las visitas.
  String? get ubicacionCliente {
    final base = ubicacionCorta(municipioCliente, estadoCliente);
    if (base == null) return null;
    final col = (coloniaCliente ?? '').trim();
    return col.isEmpty ? base : 'Col. $col, $base';
  }

  String get montoTexto => textoPrecio(monto, tipoPago);

  bool get completada => estado == EstadoSolicitud.completado;

  /// Completada y todavía sin la calificación del usuario de la sesión.
  bool get porCalificar => completada && !yaCalifique;

  /// Datos de la otra persona, vista desde [idYo].
  ({int id, String nombre, String? foto}) contraparte(int idYo) => idYo == idCliente
      ? (id: idTrabajador, nombre: nombreTrabajador, foto: fotoTrabajador)
      : (id: idCliente, nombre: nombreCliente, foto: fotoCliente);

  Solicitud copyWith({String? estado, bool? yaCalifique}) => Solicitud(
        id: id,
        estado: estado ?? this.estado,
        tipoPago: tipoPago,
        idCategoria: idCategoria,
        categoria: categoria,
        idCliente: idCliente,
        nombreCliente: nombreCliente,
        idTrabajador: idTrabajador,
        nombreTrabajador: nombreTrabajador,
        monto: monto,
        fecha: fecha,
        fotoCliente: fotoCliente,
        fotoTrabajador: fotoTrabajador,
        yaCalifique: yaCalifique ?? this.yaCalifique,
        proximaVisita: proximaVisita,
        estadoCliente: estadoCliente,
        municipioCliente: municipioCliente,
        coloniaCliente: coloniaCliente,
      );

  factory Solicitud.fromJson(Map<String, dynamic> json) => Solicitud(
        id: enteroJson(json['id_solicitud']),
        estado: (json['estado'] as String?) ?? EstadoSolicitud.pendiente,
        tipoPago: (json['tipo_pago_acordado'] as String?) ?? '',
        monto: numeroJson(json['monto_estimado']),
        fecha: fechaJson(json['fecha_solicitud']),
        idCategoria: enteroJson(json['id_categoria']),
        categoria: (json['nombre_categoria'] as String?) ?? '',
        idCliente: enteroJson(json['id_cliente']),
        nombreCliente:
            '${json['nombre_cliente'] ?? ''} ${json['apellido_cliente'] ?? ''}'.trim(),
        fotoCliente: json['foto_cliente'] as String?,
        idTrabajador: enteroJson(json['id_trabajador']),
        nombreTrabajador:
            '${json['nombre_trabajador'] ?? ''} ${json['apellido_trabajador'] ?? ''}'.trim(),
        fotoTrabajador: json['foto_trabajador'] as String?,
        yaCalifique: boolJson(json['ya_califique']),
        proximaVisita: fechaJson(json['proxima_visita']),
        estadoCliente: json['estado_cliente'] as String?,
        municipioCliente: json['municipio_cliente'] as String?,
        coloniaCliente: json['colonia_cliente'] as String?,
      );
}
