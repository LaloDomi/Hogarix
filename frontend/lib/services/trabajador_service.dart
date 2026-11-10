import 'package:manocerca/core/models/mi_servicio.dart';
import 'package:manocerca/services/api_client.dart';

class TrabajadorService {
  TrabajadorService(this._api);
  final ApiClient _api;

  Future<PerfilTrabajador> perfil(int idUsuario) async {
    final r = await _api.get('/trabajadores/$idUsuario');
    final data = r['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Respuesta inesperada del servidor.');
    }
    return PerfilTrabajador.fromJson(data);
  }

  Future<void> actualizarDisponibilidad(bool disponible) =>
      _api.put('/trabajadores/perfil', body: {'disponible': disponible});

  Future<void> actualizarBiografia(String biografia) =>
      _api.put('/trabajadores/perfil', body: {'biografia': biografia});

  Future<void> crearServicio({
    required int idCategoria,
    required String tipoPago,
    double? precioBase,
    String? descripcion,
  }) =>
      _api.post('/trabajadores/servicios', body: _cuerpo(idCategoria, tipoPago, precioBase, descripcion));

  Future<void> actualizarServicio(
    int idServicio, {
    required int idCategoria,
    required String tipoPago,
    double? precioBase,
    String? descripcion,
  }) =>
      _api.put('/trabajadores/servicios/$idServicio',
          body: _cuerpo(idCategoria, tipoPago, precioBase, descripcion));

  Future<void> eliminarServicio(int idServicio) =>
      _api.delete('/trabajadores/servicios/$idServicio');

  Map<String, Object?> _cuerpo(
    int idCategoria,
    String tipoPago,
    double? precioBase,
    String? descripcion,
  ) =>
      {
        'id_categoria': idCategoria,
        'tipo_pago': tipoPago,
        'precio_base': precioBase,
        'descripcion_servicio': descripcion,
      };
}
