import 'package:flutter/foundation.dart';
import 'package:manocerca/core/models/usuario.dart';
import 'package:manocerca/services/almacen_sesion.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/auth_service.dart';
import 'package:manocerca/services/trabajador_service.dart';

/// Oficio y forma de cobro que el trabajador eligió al registrarse.
typedef ServicioInicial = ({int idCategoria, String tipoPago});

/// Resultado de entrar con el código del correo.
enum ResultadoAcceso { entro, faltanDatos, error }

/// Resultado de crear la cuenta. [requiereCodigo]: se mandó un código al
/// correo y hay que confirmarlo para terminar.
enum ResultadoRegistro { creada, requiereCodigo, error }

/// Estado de la sesión. El token se guarda en el dispositivo ([AlmacenSesion])
/// para que la sesión siga abierta al volver a entrar.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api, {AlmacenSesion? almacen})
      : _auth = AuthService(_api),
        _almacen = almacen ?? AlmacenSesion() {
    _api.onSesionExpirada = _sesionExpirada;
  }

  final ApiClient _api;
  final AuthService _auth;
  final AlmacenSesion _almacen;

  Usuario? _usuario;
  bool _cargando = false;
  bool _restaurando = false;
  String? _error;

  Usuario? get usuario => _usuario;
  bool get autenticado => _usuario != null;
  bool get cargando => _cargando;
  bool get restaurando => _restaurando;
  String? get error => _error;

  /// Al abrir la app: si hay un token guardado y sigue siendo válido, entra directo.
  Future<void> restaurarSesion() async {
    final token = await _almacen.leer();
    if (token == null || token.isEmpty) return;
    _restaurando = true;
    notifyListeners();
    _api.token = token;
    try {
      _usuario = await _auth.perfil();
    } on ApiException catch (e) {
      _api.token = null;
      // Token vencido o inválido: se olvida. Si solo no hubo conexión, se conserva.
      if (e.statusCode == 401 || e.statusCode == 403) await _almacen.borrar();
    } catch (_) {
      _api.token = null;
    } finally {
      _restaurando = false;
      notifyListeners();
    }
  }

  /// [usuario] es el correo o el número de teléfono.
  Future<bool> login({required String usuario, required String contrasena}) =>
      _ejecutar(() => _auth.login(usuario: usuario, contrasena: contrasena));

  Future<ResultadoRegistro> registrar({
    required int idRol,
    required String nombre,
    required String apellido,
    String? correo,
    required String contrasena,
    String? telefono,
    String? codigo,
    ServicioInicial? servicio,
  }) async {
    if (_cargando) return ResultadoRegistro.error;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final sesion = await _auth.registrar(
        idRol: idRol,
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        contrasena: contrasena,
        telefono: telefono,
        codigo: codigo,
      );
      if (sesion == null) return ResultadoRegistro.requiereCodigo;
      await _iniciar(sesion, servicio: servicio);
      return ResultadoRegistro.creada;
    } on ApiException catch (e) {
      _error = e.mensaje;
      return ResultadoRegistro.error;
    } catch (_) {
      _error = 'Ocurrió un error inesperado. Intenta de nuevo.';
      return ResultadoRegistro.error;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Cambia la contraseña. Devuelve el mensaje de error o null si salió bien.
  Future<String?> cambiarContrasena({required String actual, required String nueva}) async {
    try {
      await _auth.cambiarContrasena(actual: actual, nueva: nueva);
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'No se pudo cambiar la contraseña. Intenta de nuevo.';
    }
  }

  /// Pide un código al correo. No cambia el estado global: la pantalla
  /// muestra su propio indicador de carga.
  Future<({bool ok, String mensaje})> enviarCodigo({
    required String correo,
    required String proposito,
  }) async {
    try {
      final mensaje = await _auth.enviarCodigo(correo: correo, proposito: proposito);
      return (ok: true, mensaje: mensaje);
    } on ApiException catch (e) {
      return (ok: false, mensaje: e.mensaje);
    } catch (_) {
      return (ok: false, mensaje: 'No se pudo enviar el código. Intenta de nuevo.');
    }
  }

  Future<bool> restablecerContrasena({
    required String correo,
    required String codigo,
    required String contrasena,
  }) =>
      _ejecutar(() => _auth.restablecerContrasena(
            correo: correo,
            codigo: codigo,
            contrasena: contrasena,
          ));

  /// Entra (o crea la cuenta) con el código que llegó al correo.
  Future<ResultadoAcceso> accederConCodigo({
    required String correo,
    required String codigo,
    int? idRol,
    String? nombre,
    String? apellido,
    ServicioInicial? servicio,
  }) async {
    if (_cargando) return ResultadoAcceso.error;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final sesion = await _auth.accederConCodigo(
        correo: correo,
        codigo: codigo,
        idRol: idRol,
        nombre: nombre,
        apellido: apellido,
      );
      if (sesion == null) return ResultadoAcceso.faltanDatos;
      await _iniciar(sesion, servicio: servicio);
      return ResultadoAcceso.entro;
    } on ApiException catch (e) {
      _error = e.mensaje;
      return ResultadoAcceso.error;
    } catch (_) {
      _error = 'Ocurrió un error inesperado. Intenta de nuevo.';
      return ResultadoAcceso.error;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Vuelve a pedir el perfil (ubicación, foto…). No falla si no hay red.
  Future<void> refrescarPerfil() async {
    final actual = _usuario;
    if (actual == null) return;
    try {
      final p = await _auth.perfil();
      _usuario = actual.conPerfil(p);
      notifyListeners();
    } catch (_) {}
  }

  /// Guarda cambios del perfil. Devuelve el mensaje de error o null si salió bien.
  Future<String?> actualizarPerfil(Map<String, Object?> cambios) async {
    final actual = _usuario;
    if (actual == null) return 'Inicia sesión de nuevo.';
    try {
      final p = await _auth.actualizarPerfil(cambios);
      _usuario = actual.conPerfil(p);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'No se pudieron guardar los cambios.';
    }
  }

  /// Guarda el correo verificado. Devuelve el mensaje de error o null.
  Future<String?> cambiarCorreo({required String correo, required String codigo}) async {
    final actual = _usuario;
    if (actual == null) return 'Inicia sesión de nuevo.';
    try {
      final p = await _auth.cambiarCorreo(correo: correo, codigo: codigo);
      _usuario = actual.conPerfil(p);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'No se pudo guardar el correo.';
    }
  }

  void cerrarSesion() {
    _api.token = null;
    _usuario = null;
    _error = null;
    _almacen.borrar();
    notifyListeners();
  }

  void limpiarError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> _iniciar(Sesion sesion, {ServicioInicial? servicio}) async {
    _api.token = sesion.token;
    _usuario = sesion.usuario;
    await _almacen.guardar(sesion.token);
    // Trabajador nuevo que eligió a qué se dedica: se registra su primer
    // servicio para que aparezca de inmediato en esa categoría.
    if (servicio != null && sesion.usuario.esTrabajador) {
      try {
        await TrabajadorService(_api).crearServicio(
          idCategoria: servicio.idCategoria,
          tipoPago: servicio.tipoPago,
        );
      } catch (_) {
        // Si falla, puede agregarlo después en "Mis servicios".
      }
    }
    // El login trae lo básico; el perfil completo (ubicación, foto) se pide aparte.
    try {
      final p = await _auth.perfil();
      _usuario = sesion.usuario.conPerfil(p);
    } catch (_) {}
  }

  Future<bool> _ejecutar(Future<Sesion> Function() accion, {ServicioInicial? servicio}) async {
    if (_cargando) return false;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await _iniciar(await accion(), servicio: servicio);
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      return false;
    } catch (_) {
      _error = 'Ocurrió un error inesperado. Intenta de nuevo.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void _sesionExpirada() {
    cerrarSesion();
    _error = 'Tu sesión expiró. Inicia sesión de nuevo.';
    notifyListeners();
  }
}
