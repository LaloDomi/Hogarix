import 'package:manocerca/core/models/conversacion.dart';
import 'package:manocerca/services/api_client.dart';

class ChatService {
  ChatService(this._api);
  final ApiClient _api;

  Future<List<Conversacion>> conversaciones() async {
    final r = await _api.get('/conversaciones', query: {'limite': 50});
    final data = r['data'];
    if (data is! List) throw const ApiException('Respuesta inesperada del servidor.');
    return data.map((e) => Conversacion.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Abre (o reutiliza) el chat con [idOtro] y devuelve su id.
  Future<int> abrir(int idOtro) async {
    final r = await _api.post('/conversaciones', body: {'id_usuario': idOtro});
    final data = r['data'];
    if (data is! Map || data['id_conversacion'] == null) {
      throw const ApiException('Respuesta inesperada del servidor.');
    }
    return (data['id_conversacion'] as num).toInt();
  }

  /// Sin [despuesDe]: los últimos mensajes. Con [despuesDe]: solo los nuevos.
  Future<List<Mensaje>> mensajes(int idConversacion, {int? despuesDe}) async {
    final r = await _api.get('/conversaciones/$idConversacion/mensajes',
        query: {'despues_de': despuesDe, 'limite': 50});
    final data = r['data'];
    if (data is! List) throw const ApiException('Respuesta inesperada del servidor.');
    return data.map((e) => Mensaje.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Mensaje?> enviar(int idConversacion, {String? contenido, String? urlImagen}) async {
    final r = await _api.post('/conversaciones/$idConversacion/mensajes', body: {
      if (contenido != null) 'contenido': contenido,
      if (urlImagen != null) 'url_imagen': urlImagen,
    });
    final data = r['data'];
    return data is Map<String, dynamic> ? Mensaje.fromJson(data) : null;
  }

  Future<void> marcarLeida(int idConversacion) =>
      _api.patch('/conversaciones/$idConversacion/leida');

  Future<int> noLeidos() async {
    final r = await _api.get('/conversaciones/no-leidos');
    final data = r['data'];
    return data is Map ? ((data['total'] as num?)?.toInt() ?? 0) : 0;
  }
}

class NotificacionService {
  NotificacionService(this._api);
  final ApiClient _api;

  Future<List<Notificacion>> listar({int limite = 50, bool soloNoLeidas = false}) async {
    final r = await _api.get('/notificaciones', query: {
      'limite': limite,
      if (soloNoLeidas) 'no_leidas': 'true',
    });
    final data = r['data'];
    if (data is! List) throw const ApiException('Respuesta inesperada del servidor.');
    return data.map((e) => Notificacion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> noLeidas() async {
    final r = await _api.get('/notificaciones/no-leidas');
    final data = r['data'];
    return data is Map ? ((data['total'] as num?)?.toInt() ?? 0) : 0;
  }

  Future<void> marcarLeida(int id) => _api.patch('/notificaciones/$id/leida');
  Future<void> marcarTodas() => _api.patch('/notificaciones/leidas');
}
