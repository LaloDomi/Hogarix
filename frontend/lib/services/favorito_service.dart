import 'package:manocerca/core/utils/json.dart';
import 'package:manocerca/services/api_client.dart';

/// Un trabajador guardado como favorito por el cliente.
class Favorito {
  final int idUsuario;
  final String nombre;
  final String? foto;
  final double? calificacion;
  final bool disponible;

  const Favorito({
    required this.idUsuario,
    required this.nombre,
    this.foto,
    this.calificacion,
    this.disponible = false,
  });

  factory Favorito.fromJson(Map<String, dynamic> json) => Favorito(
        idUsuario: enteroJson(json['id_usuario']),
        nombre: '${json['nombre'] ?? ''} ${json['apellido'] ?? ''}'.trim(),
        foto: json['foto_perfil'] as String?,
        calificacion: numeroJson(json['calificacion_promedio']),
        disponible: boolJson(json['disponible']),
      );
}

/// Favoritos del cliente (solo clientes pueden usarlos).
class FavoritoService {
  FavoritoService(this._api);
  final ApiClient _api;

  Future<List<Favorito>> listar() async {
    final r = await _api.get('/favoritos');
    final data = r['data'];
    if (data is! List) throw const ApiException('Respuesta inesperada del servidor.');
    return data.map((e) => Favorito.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> agregar(int idTrabajador) => _api.post('/favoritos/$idTrabajador');
  Future<void> quitar(int idTrabajador) => _api.delete('/favoritos/$idTrabajador');
}
