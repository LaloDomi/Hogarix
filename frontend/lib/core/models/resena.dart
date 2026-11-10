import 'package:manocerca/core/utils/json.dart';

/// Una calificación que alguien dejó tras un trabajo completado.
/// Funciona en ambos sentidos: el cliente califica al trabajador y el
/// trabajador califica al cliente (como en Uber).
class Resena {
  final int id;
  final int calificacion;
  final String? comentario;
  final DateTime? fecha;
  final int idAutor;
  final String nombreAutor;
  final String? fotoAutor;

  const Resena({
    required this.id,
    required this.calificacion,
    required this.idAutor,
    required this.nombreAutor,
    this.comentario,
    this.fecha,
    this.fotoAutor,
  });

  factory Resena.fromJson(Map<String, dynamic> json) => Resena(
        id: enteroJson(json['id_resena']),
        calificacion: enteroJson(json['calificacion']).clamp(1, 5),
        comentario: json['comentario'] as String?,
        fecha: fechaJson(json['fecha_creacion']),
        idAutor: enteroJson(json['id_autor']),
        nombreAutor: '${json['nombre'] ?? ''} ${json['apellido'] ?? ''}'.trim(),
        fotoAutor: json['foto_perfil'] as String?,
      );
}

/// Promedio y reparto de estrellas de una lista de reseñas.
class ResumenResenas {
  final double? promedio;
  final int total;

  /// conteo[0] = reseñas de 5 estrellas … conteo[4] = de 1 estrella.
  final List<int> conteo;

  const ResumenResenas({this.promedio, this.total = 0, this.conteo = const [0, 0, 0, 0, 0]});

  factory ResumenResenas.de(List<Resena> resenas) {
    if (resenas.isEmpty) return const ResumenResenas();
    final conteo = List.filled(5, 0);
    var suma = 0;
    for (final r in resenas) {
      suma += r.calificacion;
      conteo[5 - r.calificacion]++;
    }
    return ResumenResenas(
      promedio: suma / resenas.length,
      total: resenas.length,
      conteo: conteo,
    );
  }
}
