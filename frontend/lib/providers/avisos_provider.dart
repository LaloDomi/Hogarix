import 'package:flutter/foundation.dart';
import 'package:manocerca/core/models/conversacion.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/chat_service.dart';

/// Contador de notificaciones sin leer, compartido por toda la app.
/// MainShell lo revisa cada cierto tiempo mientras la app está abierta y
/// muestra un aviso cuando llega una notificación nueva.
class AvisosProvider extends ChangeNotifier {
  AvisosProvider(this._api);
  final ApiClient _api;

  int _noLeidas = 0;
  int get noLeidas => _noLeidas;

  /// Id de la notificación más reciente que ya se vio (o se avisó).
  int? _ultimoId;
  bool _revisando = false;

  /// Revisa el servidor. Devuelve la notificación más reciente si llegó una
  /// nueva desde la revisión anterior (la primera revisión no avisa).
  Future<Notificacion?> revisar() async {
    if (_revisando) return null;
    _revisando = true;
    try {
      final servicio = NotificacionService(_api);
      final total = await servicio.noLeidas();
      Notificacion? nueva;
      if (total > 0) {
        final recientes = await servicio.listar(limite: 1, soloNoLeidas: true);
        final ultima = recientes.isEmpty ? null : recientes.first;
        if (ultima != null) {
          final anterior = _ultimoId;
          if (anterior != null && ultima.id > anterior) nueva = ultima;
          if (anterior == null || ultima.id > anterior) _ultimoId = ultima.id;
        }
      } else {
        _ultimoId ??= 0;
      }
      if (total != _noLeidas) {
        _noLeidas = total;
        notifyListeners();
      }
      return nueva;
    } catch (_) {
      // Sin conexión: se intenta en la siguiente revisión.
      return null;
    } finally {
      _revisando = false;
    }
  }

  /// Al entrar con otra sesión. [notificar] en false si se llama durante la
  /// construcción de la pantalla.
  void reiniciar({bool notificar = true}) {
    _noLeidas = 0;
    _ultimoId = null;
    if (notificar) notifyListeners();
  }
}
