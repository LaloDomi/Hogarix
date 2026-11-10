import 'package:manocerca/core/models/pro.dart';
import 'package:manocerca/services/api_client.dart';

class ServicioService {
  ServicioService(this._api);
  final ApiClient _api;

  /// Profesionales que ofrecen servicios en una categoría.
  /// [tipoPago]: 'Día', 'Destajo', 'Por trabajo' o 'Por hora' (null = todos).
  Future<List<Pro>> buscar({required int idCategoria, String? tipoPago}) async {
    final r = await _api.get('/servicios/buscar', query: {
      'id_categoria': idCategoria,
      'tipo_pago': tipoPago,
    });
    final data = r['data'];
    if (data is! List) throw const ApiException('Respuesta inesperada del servidor.');
    return data
        .map((e) => Pro.fromServicioJson(e as Map<String, dynamic>, idCategoria: idCategoria))
        .toList();
  }
}
