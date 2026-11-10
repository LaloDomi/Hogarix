import 'package:manocerca/core/models/solicitud.dart';
import 'package:manocerca/services/api_client.dart';

class SolicitudService {
  SolicitudService(this._api);
  final ApiClient _api;

  /// Solicitudes donde participa el usuario de la sesión (como cliente o trabajador).
  Future<List<Solicitud>> listar({String? estado, int limite = 50}) async {
    final r = await _api.get('/solicitudes', query: {'estado': estado, 'limite': limite});
    final data = r['data'];
    if (data is! List) throw const ApiException('Respuesta inesperada del servidor.');
    return data.map((e) => Solicitud.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Solo clientes.
  Future<void> crear({
    required int idTrabajador,
    required int idCategoria,
    required String tipoPago,
    double? monto,
  }) =>
      _api.post('/solicitudes', body: {
        'id_trabajador': idTrabajador,
        'id_categoria': idCategoria,
        'tipo_pago_acordado': tipoPago,
        if (monto != null) 'monto_estimado': monto,
      });

  Future<void> cambiarEstado(int idSolicitud, String estado) =>
      _api.patch('/solicitudes/$idSolicitud/estado', body: {'estado': estado});
}
