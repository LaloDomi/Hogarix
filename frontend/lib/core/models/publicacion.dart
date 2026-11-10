import 'package:manocerca/core/utils/json.dart';

/// Una publicación de trabajo (tipo Facebook): título, texto y fotos.
class Publicacion {
  final int id;
  final String titulo;
  final String contenido;
  final DateTime? fecha;
  final int idAutor;
  final String nombreAutor;
  final String? fotoAutor;
  final int totalLikes;
  final int totalComentarios;
  final bool meGusta;

  /// Rutas tal como las guarda el backend (`/uploads/...` o `https://...`).
  final List<String> imagenes;

  const Publicacion({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.idAutor,
    required this.nombreAutor,
    this.fecha,
    this.fotoAutor,
    this.totalLikes = 0,
    this.totalComentarios = 0,
    this.meGusta = false,
    this.imagenes = const [],
  });

  String? get portada => imagenes.isEmpty ? null : imagenes.first;

  Publicacion copyWith({int? totalLikes, int? totalComentarios, bool? meGusta}) => Publicacion(
        id: id,
        titulo: titulo,
        contenido: contenido,
        fecha: fecha,
        idAutor: idAutor,
        nombreAutor: nombreAutor,
        fotoAutor: fotoAutor,
        totalLikes: totalLikes ?? this.totalLikes,
        totalComentarios: totalComentarios ?? this.totalComentarios,
        meGusta: meGusta ?? this.meGusta,
        imagenes: imagenes,
      );

  factory Publicacion.fromJson(Map<String, dynamic> json) => Publicacion(
        id: enteroJson(json['id_publicacion']),
        titulo: (json['titulo'] as String?) ?? '',
        contenido: (json['contenido'] as String?) ?? '',
        fecha: fechaJson(json['fecha_creacion']),
        idAutor: enteroJson(json['id_autor']),
        nombreAutor: '${json['nombre'] ?? ''} ${json['apellido'] ?? ''}'.trim(),
        fotoAutor: json['foto_perfil'] as String?,
        totalLikes: enteroJson(json['total_likes']),
        totalComentarios: enteroJson(json['total_comentarios']),
        meGusta: boolJson(json['me_gusta']),
        imagenes: listaTextosJson(json['imagenes']),
      );
}

class Comentario {
  final int id;
  final String contenido;
  final DateTime? fecha;
  final int idUsuario;
  final String nombre;
  final String? foto;

  const Comentario({
    required this.id,
    required this.contenido,
    required this.idUsuario,
    required this.nombre,
    this.fecha,
    this.foto,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) => Comentario(
        id: enteroJson(json['id_comentario']),
        contenido: (json['contenido'] as String?) ?? '',
        fecha: fechaJson(json['fecha_creacion']),
        idUsuario: enteroJson(json['id_usuario']),
        nombre: '${json['nombre'] ?? ''} ${json['apellido'] ?? ''}'.trim(),
        foto: json['foto_perfil'] as String?,
      );
}
