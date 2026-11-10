import 'package:manocerca/core/models/evento_agenda.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/services/api_client.dart';

class AgendaService {
  AgendaService(this._api);
  final ApiClient _api;

  /// Eventos que tocan el rango [desde, hasta).
  Future<List<EventoAgenda>> listar(DateTime desde, DateTime hasta) async {
    final r = await _api.get('/agenda', query: {
      'desde': formatoSql(desde),
      'hasta': formatoSql(hasta),
    });
    final data = r['data'];
    if (data is! List) throw const ApiException('Respuesta inesperada del servidor.');
    return data
        .map((e) => EventoAgenda.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> crear({
    required String titulo,
    required DateTime inicio,
    required DateTime fin,
    String? descripcion,
  }) =>
      _api.post('/agenda', body: _cuerpo(titulo, inicio, fin, descripcion));

  Future<void> actualizar(
    int id, {
    required String titulo,
    required DateTime inicio,
    required DateTime fin,
    String? descripcion,
  }) =>
      _api.put('/agenda/$id', body: _cuerpo(titulo, inicio, fin, descripcion));

  Future<void> eliminar(int id) => _api.delete('/agenda/$id');

  Map<String, Object?> _cuerpo(
          String titulo, DateTime inicio, DateTime fin, String? descripcion) =>
      {
        'titulo': titulo,
        'descripcion': descripcion,
        'fecha_inicio': formatoSql(inicio),
        'fecha_fin': formatoSql(fin),
      };
}
