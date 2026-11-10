import 'package:manocerca/core/models/usuario.dart';
import 'package:manocerca/services/api_client.dart';

typedef Sesion = ({String token, Usuario usuario});

class AuthService {
  AuthService(this._api);
  final ApiClient _api;

  /// [usuario] es el correo o el número de teléfono.
  Future<Sesion> login({required String usuario, required String contrasena}) async {
    final r = await _api.post('/auth/login', body: {
      'identificador': usuario,
      // Compatibilidad con servidores que aún no tienen el login por teléfono.
      if (usuario.contains('@')) 'correo': usuario,
      'contrasena': contrasena,
    });
    return _sesion(r);
  }

  /// Devuelve null cuando el servidor mandó un código al correo para
  /// confirmarlo: hay que volver a llamar con [codigo].
  Future<Sesion?> registrar({
    required int idRol,
    required String nombre,
    required String apellido,
    String? correo,
    required String contrasena,
    String? telefono,
    String? codigo,
  }) async {
    final r = await _api.post('/auth/registro', body: {
      'id_rol': idRol,
      'nombre': nombre,
      'apellido': apellido,
      if (correo != null && correo.isNotEmpty) 'correo': correo,
      'contrasena': contrasena,
      if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
      if (codigo != null && codigo.isNotEmpty) 'codigo': codigo,
    });
    if (r['requiere_codigo'] == true) return null;
    return _sesion(r);
  }

  /// Cambia la contraseña del usuario con sesión.
  Future<void> cambiarContrasena({required String actual, required String nueva}) =>
      _api.put('/auth/contrasena', body: {'actual': actual, 'nueva': nueva});

  /// Perfil completo del usuario de la sesión (ubicación, foto, etc.).
  Future<Usuario> perfil() async {
    final r = await _api.get('/auth/perfil');
    final u = r['usuario'];
    if (u is! Map<String, dynamic>) throw const ApiException('Respuesta inesperada del servidor.');
    return Usuario.fromJson(u);
  }

  /// Solo se mandan los campos presentes. '' borra un dato opcional.
  Future<Usuario> actualizarPerfil(Map<String, Object?> cambios) async {
    final r = await _api.put('/auth/perfil', body: cambios);
    final u = r['usuario'];
    if (u is! Map<String, dynamic>) throw const ApiException('Respuesta inesperada del servidor.');
    return Usuario.fromJson(u);
  }

  /// Manda un código de 6 dígitos al correo.
  /// [proposito]: `restablecer` (olvidé mi contraseña) o `acceso` (entrar sin contraseña).
  /// Devuelve el mensaje del servidor para mostrarlo.
  Future<String> enviarCodigo({required String correo, required String proposito}) async {
    final r = await _api.post('/auth/codigo', body: {
      'correo': correo,
      'proposito': proposito,
    });
    return (r['mensaje'] as String?) ?? 'Te enviamos un código a tu correo.';
  }

  /// Cambia la contraseña con el código del correo y deja la sesión iniciada.
  Future<Sesion> restablecerContrasena({
    required String correo,
    required String codigo,
    required String contrasena,
  }) async {
    final r = await _api.post('/auth/contrasena/restablecer', body: {
      'correo': correo,
      'codigo': codigo,
      'contrasena': contrasena,
    });
    return _sesion(r);
  }

  /// Entra con el código del correo. Devuelve null si el correo todavía no
  /// tiene cuenta y hay que pedir rol, nombre y apellido para crearla.
  Future<Sesion?> accederConCodigo({
    required String correo,
    required String codigo,
    int? idRol,
    String? nombre,
    String? apellido,
  }) async {
    final r = await _api.post('/auth/codigo/verificar', body: {
      'correo': correo,
      'codigo': codigo,
      if (idRol != null) 'id_rol': idRol,
      if (nombre != null) 'nombre': nombre,
      if (apellido != null) 'apellido': apellido,
    });
    if (r['requiere_registro'] == true) return null;
    return _sesion(r);
  }

  /// Agrega o cambia el correo de la cuenta con el código que llegó a ese
  /// correo (pedido antes con [enviarCodigo] y propósito `acceso`).
  Future<Usuario> cambiarCorreo({required String correo, required String codigo}) async {
    final r = await _api.put('/auth/correo', body: {'correo': correo, 'codigo': codigo});
    final u = r['usuario'];
    if (u is! Map<String, dynamic>) throw const ApiException('Respuesta inesperada del servidor.');
    return Usuario.fromJson(u);
  }

  Sesion _sesion(Map<String, dynamic> r) {
    final token = r['token'];
    final usuario = r['usuario'];
    if (token is! String || usuario is! Map<String, dynamic>) {
      throw const ApiException('Respuesta inesperada del servidor.');
    }
    return (token: token, usuario: Usuario.fromJson(usuario));
  }
}
