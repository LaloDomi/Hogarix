import 'package:flutter/foundation.dart';
import 'package:manocerca/core/models/categoria.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/categoria_service.dart';

/// Categorías de oficios. Se piden una vez y se reutilizan en toda la app.
class CategoriasProvider extends ChangeNotifier {
  CategoriasProvider(ApiClient api) : _service = CategoriaService(api);

  final CategoriaService _service;

  List<Categoria> _items = const [];
  bool _cargando = false;
  String? _error;

  List<Categoria> get items => _items;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Carga solo si todavía no hay datos ni una carga en curso.
  Future<void> cargarSiHaceFalta() async {
    if (_items.isEmpty && !_cargando) await recargar();
  }

  Future<void> recargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.listar();
    } on ApiException catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = 'No se pudieron cargar las categorías.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
