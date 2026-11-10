import 'package:manocerca/core/models/categoria.dart';
import 'package:manocerca/services/api_client.dart';

class CategoriaService {
  CategoriaService(this._api);
  final ApiClient _api;

  Future<List<Categoria>> listar() async {
    final r = await _api.get('/categorias');
    final data = r['data'];
    if (data is! List) throw const ApiException('Respuesta inesperada del servidor.');
    return data
        .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
