import 'package:shared_preferences/shared_preferences.dart';

/// Guarda el token en el dispositivo para no pedir login cada vez que se abre
/// la app. Si el almacenamiento no está disponible (p. ej. en pruebas), la
/// sesión simplemente vive en memoria.
class AlmacenSesion {
  static const _clave = 'hogarix_token';

  Future<String?> leer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_clave);
    } catch (_) {
      return null;
    }
  }

  Future<void> guardar(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clave, token);
    } catch (_) {
      // Sin almacenamiento: la sesión dura mientras la app esté abierta.
    }
  }

  Future<void> borrar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clave);
    } catch (_) {}
  }
}
