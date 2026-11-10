import 'package:manocerca/core/utils/json.dart';

class Conversacion {
  final int id;
  final int idOtro;
  final String nombreOtro;
  final String? fotoOtro;
  final String? ultimoMensaje;
  final bool ultimoTieneImagen;
  final bool ultimoEsMio;
  final DateTime? fecha;
  final int noLeidos;

  const Conversacion({
    required this.id,
    required this.idOtro,
    required this.nombreOtro,
    this.fotoOtro,
    this.ultimoMensaje,
    this.ultimoTieneImagen = false,
    this.ultimoEsMio = false,
    this.fecha,
    this.noLeidos = 0,
  });

  String get vistaPrevia {
    final texto = (ultimoMensaje ?? '').trim();
    final base = texto.isNotEmpty ? texto : (ultimoTieneImagen ? '📷 Foto' : '');
    return ultimoEsMio ? 'Tú: $base' : base;
  }

  factory Conversacion.fromJson(Map<String, dynamic> json) => Conversacion(
        id: enteroJson(json['id_conversacion']),
        idOtro: enteroJson(json['id_otro_usuario']),
        nombreOtro:
            '${json['nombre_otro_usuario'] ?? ''} ${json['apellido_otro_usuario'] ?? ''}'.trim(),
        fotoOtro: json['foto_otro_usuario'] as String?,
        ultimoMensaje: json['ultimo_mensaje'] as String?,
        ultimoTieneImagen: json['ultima_imagen'] != null,
        ultimoEsMio: boolJson(json['ultimo_es_mio']),
        fecha: fechaJson(json['fecha_ultimo_mensaje']),
        noLeidos: enteroJson(json['no_leidos']),
      );
}

class Mensaje {
  final int id;
  final bool esMio;
  final String? contenido;
  final String? urlImagen;
  final DateTime? fecha;
  final bool leido;

  const Mensaje({
    required this.id,
    required this.esMio,
    this.contenido,
    this.urlImagen,
    this.fecha,
    this.leido = false,
  });

  factory Mensaje.fromJson(Map<String, dynamic> json) => Mensaje(
        id: enteroJson(json['id_mensaje']),
        esMio: boolJson(json['es_mio']),
        contenido: json['contenido'] as String?,
        urlImagen: json['url_imagen'] as String?,
        fecha: fechaJson(json['fecha_envio']),
        leido: boolJson(json['leido']),
      );
}

class Notificacion {
  final int id;
  final String tipo;
  final String titulo;
  final String? cuerpo;
  final int? idReferencia;
  final bool leida;
  final DateTime? fecha;

  const Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.cuerpo,
    this.idReferencia,
    this.leida = false,
    this.fecha,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
        id: enteroJson(json['id_notificacion']),
        tipo: (json['tipo'] as String?) ?? '',
        titulo: (json['titulo'] as String?) ?? '',
        cuerpo: json['cuerpo'] as String?,
        idReferencia: json['id_referencia'] == null ? null : enteroJson(json['id_referencia']),
        leida: boolJson(json['leida']),
        fecha: fechaJson(json['fecha_creacion']),
      );
}
