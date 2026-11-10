import 'package:manocerca/core/models/publicacion.dart';
import 'package:manocerca/services/api_client.dart';

/// Una foto elegida en el teléfono, lista para subir.
typedef FotoNueva = ({List<int> bytes, String nombre});

class PublicacionService {
  PublicacionService(this._api);
  final ApiClient _api;

  static const maxFotos = 10;

  /// Publicaciones de un usuario ([idUsuario]) o de todos (null), más recientes primero.
  Future<List<Publicacion>> listar({int? idUsuario, int pagina = 1, int limite = 20}) async {
    final r = await _api.get('/publicaciones', query: {
      'id_usuario': idUsuario,
      'pagina': pagina,
      'limite': limite,
    });
    final data = r['data'];
    if (data is! List) throw const ApiException('Respuesta inesperada del servidor.');
    return data.map((e) => Publicacion.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Sube las fotos una por una y luego crea la publicación con sus rutas.
  /// [alAvanzar] recibe cuántas fotos van subidas.
  Future<void> crear({
    required String titulo,
    required String contenido,
    required List<FotoNueva> fotos,
    void Function(int subidas)? alAvanzar,
  }) async {
    final rutas = <String>[];
    for (final foto in fotos) {
      final data = await _api.subirImagen(foto.bytes, foto.nombre);
      rutas.add(data['ruta'] as String);
      alAvanzar?.call(rutas.length);
    }
    await _api.post('/publicaciones', body: {
      'titulo': titulo,
      'contenido': contenido,
      'imagenes': rutas,
    });
  }

  Future<void> eliminar(int id) => _api.delete('/publicaciones/$id');

  /// Devuelve el nuevo total de likes.
  Future<int?> darLike(int id) async {
    final r = await _api.post('/publicaciones/$id/like');
    return (r['total_likes'] as num?)?.toInt();
  }

  Future<int?> quitarLike(int id) async {
    final r = await _api.delete('/publicaciones/$id/like');
    return (r['total_likes'] as num?)?.toInt();
  }

  Future<List<Comentario>> comentarios(int id) async {
    final r = await _api.get('/publicaciones/$id/comentarios', query: {'limite': 50});
    final data = r['data'];
    if (data is! List) throw const ApiException('Respuesta inesperada del servidor.');
    return data.map((e) => Comentario.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> comentar(int id, String contenido) =>
      _api.post('/publicaciones/$id/comentarios', body: {'contenido': contenido});
}
