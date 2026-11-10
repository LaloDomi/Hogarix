import 'package:manocerca/core/models/visita.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/services/api_client.dart';

class VisitaService {
  VisitaService(this._api);
  final ApiClient _api;

  Future<List<Visita>> listar(DateTime desde, DateTime hasta) async {
    final r = await _api.get('/visitas', query: {
      'desde': formatoSql(desde),
      'hasta': formatoSql(hasta),
    });
    final data = r['data'];
    if (data is! List) throw const ApiException('Respuesta inesperada del servidor.');
    return data.map((e) => Visita.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> crear({
    required int idSolicitud,
    required DateTime inicio,
    required DateTime fin,
    String? direccion,
    String? notas,
  }) =>
      _api.post('/visitas', body: {
        'id_solicitud': idSolicitud,
        ..._horario(inicio, fin, direccion, notas),
      });

  Future<void> reprogramar(
    int idVisita, {
    required DateTime inicio,
    required DateTime fin,
    String? direccion,
    String? notas,
  }) =>
      _api.put('/visitas/$idVisita', body: _horario(inicio, fin, direccion, notas));

  /// 'Confirmada', 'Cancelada' o 'Realizada'.
  Future<void> cambiarEstado(int idVisita, String estado) =>
      _api.patch('/visitas/$idVisita/estado', body: {'estado': estado});

  Map<String, Object?> _horario(
          DateTime inicio, DateTime fin, String? direccion, String? notas) =>
      {
        'fecha_inicio': formatoSql(inicio),
        'fecha_fin': formatoSql(fin),
        'direccion': direccion ?? '',
        'notas': notas ?? '',
      };
}
