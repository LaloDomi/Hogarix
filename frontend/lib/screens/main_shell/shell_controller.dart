import 'package:flutter/foundation.dart';

/// Permite que cualquier pantalla cambie de pestaña (p. ej. el buscador del
/// Inicio abre "Buscar"). Vive sobre el MaterialApp para que también lo usen
/// las pantallas abiertas encima de la barra inferior.
class ShellController extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  /// Texto con el que debe abrirse la pestaña Buscar (se consume una vez).
  String? busquedaPendiente;

  /// Al iniciar sesión se vuelve a la primera pestaña.
  void reiniciar() {
    _index = 0;
    busquedaPendiente = null;
  }

  void ir(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }
}
