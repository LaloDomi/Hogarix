import 'package:manocerca/core/utils/fechas.dart';

/// Un bloque de la agenda del trabajador (cita, trabajo, tiempo ocupado).
class EventoAgenda {
  final int id;
  final String titulo;
  final String? descripcion;
  final DateTime inicio;
  final DateTime fin;

  const EventoAgenda({
    required this.id,
    required this.titulo,
    required this.inicio,
    required this.fin,
    this.descripcion,
  });

  /// ¿El evento ocupa alguna parte de [dia]?
  bool ocurreEn(DateTime dia) {
    final desde = soloDia(dia);
    final hasta = DateTime(dia.year, dia.month, dia.day + 1);
    return inicio.isBefore(hasta) && fin.isAfter(desde);
  }

  /// "09:00 – 12:30", o con fechas si cruza de día.
  String get rangoTexto {
    if (mismoDia(inicio, fin)) return '${horaTexto(inicio)} – ${horaTexto(fin)}';
    return '${diaMesAbreviado(inicio)} ${horaTexto(inicio)} – '
        '${diaMesAbreviado(fin)} ${horaTexto(fin)}';
  }

  factory EventoAgenda.fromJson(Map<String, dynamic> json) => EventoAgenda(
        id: (json['id_evento'] as num).toInt(),
        titulo: json['titulo'] as String,
        descripcion: json['descripcion'] as String?,
        inicio: parseFechaSql(json['fecha_inicio'] as String),
        fin: parseFechaSql(json['fecha_fin'] as String),
      );
}
