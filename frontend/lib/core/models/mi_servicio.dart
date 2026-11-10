import 'package:manocerca/core/data/ubicaciones_mx.dart';
import 'package:manocerca/core/utils/json.dart';
import 'package:manocerca/core/utils/precio.dart';

/// Un servicio que ofrece el trabajador autenticado.
class MiServicio {
  final int id;
  final int idCategoria;
  final String categoria;
  final String tipoPago;
  final double? precioBase;
  final String? descripcion;

  const MiServicio({
    required this.id,
    required this.idCategoria,
    required this.categoria,
    required this.tipoPago,
    this.precioBase,
    this.descripcion,
  });

  String get precioTexto => textoPrecio(precioBase, tipoPago);

  factory MiServicio.fromJson(Map<String, dynamic> json) => MiServicio(
        id: (json['id_servicio'] as num).toInt(),
        idCategoria: (json['id_categoria'] as num).toInt(),
        categoria: json['nombre_categoria'] as String,
        tipoPago: json['tipo_pago'] as String,
        // MySQL entrega DECIMAL como texto ("150.00").
        precioBase: json['precio_base'] == null
            ? null
            : double.tryParse('${json['precio_base']}'),
        descripcion: json['descripcion_servicio'] as String?,
      );
}

/// Perfil público de un trabajador (`GET /api/trabajadores/:id`). "Mis
/// servicios" solo usa [disponible] y [servicios]; el perfil usa todo.
class PerfilTrabajador {
  final bool disponible;
  final List<MiServicio> servicios;

  final int? idUsuario;
  final String nombre;
  final String apellido;
  final String? fotoPerfil;
  final DateTime? fechaRegistro;
  final String? biografia;

  /// Todavía no existen en la base; se muestran en cuanto el backend los envíe.
  final int? edad;
  final String? sexo;
  final String? estadoMx;
  final String? municipio;

  /// null mientras no tenga reseñas.
  final double? calificacion;
  final int totalResenas;

  const PerfilTrabajador({
    required this.disponible,
    required this.servicios,
    this.idUsuario,
    this.nombre = '',
    this.apellido = '',
    this.fotoPerfil,
    this.fechaRegistro,
    this.biografia,
    this.edad,
    this.sexo,
    this.estadoMx,
    this.municipio,
    this.calificacion,
    this.totalResenas = 0,
  });

  String get nombreCompleto => '$nombre $apellido'.trim();

  String? get ubicacion => ubicacionCorta(municipio, estadoMx);

  /// Oficios sin repetir, en el orden en que llegan.
  List<String> get oficios => {for (final s in servicios) s.categoria}.toList();

  /// Precio más bajo y más alto entre sus servicios con precio.
  ({double min, double max})? get rangoPrecios {
    final precios = [
      for (final s in servicios)
        if (s.precioBase != null) s.precioBase!,
    ];
    if (precios.isEmpty) return null;
    precios.sort();
    return (min: precios.first, max: precios.last);
  }

  PerfilTrabajador copyWith({bool? disponible, String? biografia}) => PerfilTrabajador(
        disponible: disponible ?? this.disponible,
        servicios: servicios,
        idUsuario: idUsuario,
        nombre: nombre,
        apellido: apellido,
        fotoPerfil: fotoPerfil,
        fechaRegistro: fechaRegistro,
        biografia: biografia ?? this.biografia,
        edad: edad,
        sexo: sexo,
        estadoMx: estadoMx,
        municipio: municipio,
        calificacion: calificacion,
        totalResenas: totalResenas,
      );

  factory PerfilTrabajador.fromJson(Map<String, dynamic> json) => PerfilTrabajador(
        disponible: boolJson(json['disponible']),
        servicios: ((json['servicios'] as List?) ?? const [])
            .map((e) => MiServicio.fromJson(e as Map<String, dynamic>))
            .toList(),
        idUsuario: json['id_usuario'] == null ? null : enteroJson(json['id_usuario']),
        nombre: (json['nombre'] as String?) ?? '',
        apellido: (json['apellido'] as String?) ?? '',
        fotoPerfil: json['foto_perfil'] as String?,
        fechaRegistro: fechaJson(json['fecha_registro']),
        biografia: json['biografia'] as String?,
        edad: json['edad'] == null ? null : enteroJson(json['edad']),
        sexo: json['sexo'] as String?,
        estadoMx: json['estado_mx'] as String?,
        municipio: json['municipio'] as String?,
        calificacion: numeroJson(json['calificacion_promedio']),
        totalResenas: enteroJson(json['total_resenas']),
      );
}
