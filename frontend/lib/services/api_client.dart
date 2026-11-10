import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:manocerca/core/config/api_config.dart';

/// Error de la API con el mensaje listo para mostrar al usuario.
class ApiException implements Exception {
  final String mensaje;
  final int? statusCode;
  const ApiException(this.mensaje, {this.statusCode});

  @override
  String toString() => mensaje;
}

/// Cliente HTTP del backend. Agrega el token y traduce las respuestas
/// `{ ok, mensaje, data }` o lanza [ApiException].
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _http;
  final String baseUrl;

  /// El token vive solo en memoria: al cerrar la app se pierde la sesión.
  String? token;

  /// Se invoca cuando el servidor rechaza el token de una sesión abierta.
  void Function()? onSesionExpirada;

  Future<Map<String, dynamic>> get(String path,
          {Map<String, Object?>? query, Duration? espera}) =>
      _send('GET', path, query: query, espera: espera);

  /// [espera]: tiempo máximo de respuesta (por defecto 15 s; la IA usa más).
  Future<Map<String, dynamic>> post(String path, {Object? body, Duration? espera}) =>
      _send('POST', path, body: body, espera: espera);

  Future<Map<String, dynamic>> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    Duration? espera,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query == null
          ? null
          : {
              for (final e in query.entries)
                if (e.value != null) e.key: '${e.value}',
            },
    );

    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    return _enviar(request, espera: espera ?? const Duration(seconds: 15));
  }

  /// Sube una imagen a `POST /api/archivos` (multipart, campo `archivo`).
  /// Devuelve el `data` del backend: `{ id_archivo, ruta, url, ... }`.
  Future<Map<String, dynamic>> subirImagen(List<int> bytes, String nombreArchivo) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/archivos'))
      ..headers['Accept'] = 'application/json'
      ..files.add(http.MultipartFile.fromBytes('archivo', bytes, filename: nombreArchivo));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    final r = await _enviar(request, espera: const Duration(seconds: 60));
    final data = r['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Respuesta inesperada del servidor.');
    }
    return data;
  }

  /// Dirección del servidor sin `/api` (ahí se sirven las imágenes subidas).
  String get servidor =>
      baseUrl.endsWith('/api') ? baseUrl.substring(0, baseUrl.length - 4) : baseUrl;

  /// Convierte la ruta guardada en la base (`/uploads/...`) en una URL completa.
  /// Las URLs `http(s)://` se devuelven tal cual. null o vacío -> null.
  String? urlDe(String? ruta) {
    if (ruta == null || ruta.trim().isEmpty) return null;
    if (ruta.startsWith('http://') || ruta.startsWith('https://')) return ruta;
    return '$servidor${ruta.startsWith('/') ? '' : '/'}$ruta';
  }

  Future<Map<String, dynamic>> _enviar(
    http.BaseRequest request, {
    Duration espera = const Duration(seconds: 15),
  }) async {
    final http.Response response;
    try {
      final stream = await _http.send(request).timeout(espera);
      response = await http.Response.fromStream(stream);
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder. Intenta de nuevo.');
    } catch (_) {
      throw const ApiException('No se pudo conectar con el servidor. Revisa tu conexión.');
    }

    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      // El cuerpo no era JSON; se maneja abajo.
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (ok && json != null) return json;

    final mensaje = (json?['mensaje'] as String?) ??
        (ok ? 'Respuesta inesperada del servidor.' : 'Error del servidor (${response.statusCode}).');

    // El backend usa 403 tanto para token inválido como para falta de rol;
    // solo el primero debe cerrar la sesión.
    final tokenRechazado = response.statusCode == 401 ||
        (response.statusCode == 403 && mensaje.startsWith('Token inválido'));
    if (token != null && tokenRechazado) onSesionExpirada?.call();

    throw ApiException(mensaje, statusCode: response.statusCode);
  }
}
