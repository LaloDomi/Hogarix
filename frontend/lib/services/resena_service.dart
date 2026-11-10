import 'package:manocerca/core/models/resena.dart';
import 'package:manocerca/services/api_client.dart';

class ResenaService {
  ResenaService(this._api);
  final ApiClient _api;

  /// Reseñas que ha recibido [idUsuario] (trabajador o cliente).
  Future<List<Resena>> deUsuario(int idUsuario, {int limite = 50}) async {
    final r = await _api.get('/resenas/usuario/$idUsuario', query: {'limite': limite});
    final data = r['data'];
    if (data is! List) throw const ApiException('Respuesta inesperada del servidor.');
    return data.map((e) => Resena.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Califica a la otra parte de una solicitud completada.
  Future<void> calificar({
    required int idSolicitud,
    required int calificacion,
    String? comentario,
  }) =>
      _api.post('/resenas', body: {
        'id_solicitud': idSolicitud,
        'calificacion': calificacion,
        if (comentario != null && comentario.trim().isNotEmpty) 'comentario': comentario.trim(),
      });
}
