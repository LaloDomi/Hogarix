import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manocerca/services/api_client.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

ApiClient _cliente(MockClientHandler handler) =>
    ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api');

void main() {
  test('GET devuelve el JSON y arma la URL con query sin valores nulos', () async {
    late Uri uri;
    final api = _cliente((req) async {
      uri = req.url;
      return _json({'ok': true, 'data': []});
    });

    final r = await api.get('/servicios/buscar', query: {'id_categoria': 3, 'tipo_pago': null});

    expect(r['ok'], true);
    expect(uri.toString(), 'http://test/api/servicios/buscar?id_categoria=3');
  });

  test('envía Authorization solo cuando hay token', () async {
    final headers = <Map<String, String>>[];
    final api = _cliente((req) async {
      headers.add(req.headers);
      return _json({'ok': true});
    });

    await api.get('/x');
    api.token = 'abc';
    await api.get('/x');

    expect(headers[0].containsKey('Authorization'), false);
    expect(headers[1]['Authorization'], 'Bearer abc');
  });

  test('POST manda el cuerpo como JSON', () async {
    String? contentType;
    Object? cuerpo;
    final api = _cliente((req) async {
      contentType = req.headers['Content-Type'];
      cuerpo = jsonDecode(req.body);
      return _json({'ok': true}, 201);
    });

    await api.post('/auth/login', body: {'correo': 'a@b.com'});

    expect(contentType, contains('application/json'));
    expect(cuerpo, {'correo': 'a@b.com'});
  });

  test('un error del backend lanza ApiException con su mensaje y código', () async {
    final api = _cliente((_) async =>
        _json({'ok': false, 'mensaje': 'Credenciales inválidas.'}, 401));

    expect(
      () => api.post('/auth/login', body: {}),
      throwsA(isA<ApiException>()
          .having((e) => e.mensaje, 'mensaje', 'Credenciales inválidas.')
          .having((e) => e.statusCode, 'statusCode', 401)),
    );
  });

  test('si no hay conexión lanza un mensaje amigable', () async {
    final api = _cliente((_) async => throw Exception('socket'));

    expect(
      () => api.get('/x'),
      throwsA(isA<ApiException>().having((e) => e.mensaje, 'mensaje', contains('No se pudo conectar'))),
    );
  });

  test('una respuesta que no es JSON lanza ApiException', () async {
    final api = _cliente((_) async => http.Response('<html>502</html>', 502));

    expect(
      () => api.get('/x'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 502)),
    );
  });

  group('sesión expirada', () {
    Future<int> intentar({required String? token, required int status, required String mensaje}) async {
      var avisos = 0;
      final api = _cliente((_) async => _json({'ok': false, 'mensaje': mensaje}, status))
        ..token = token
        ..onSesionExpirada = () => avisos++;
      try {
        await api.get('/x');
      } on ApiException {
        // esperado
      }
      return avisos;
    }

    test('401 con token avisa', () async {
      expect(await intentar(token: 't', status: 401, mensaje: 'Acceso denegado.'), 1);
    });

    test('403 por token inválido avisa', () async {
      expect(await intentar(token: 't', status: 403, mensaje: 'Token inválido o expirado.'), 1);
    });

    test('403 por falta de rol NO avisa', () async {
      expect(await intentar(token: 't', status: 403, mensaje: 'No tienes permisos para realizar esta acción.'), 0);
    });

    test('401 sin token (login fallido) NO avisa', () async {
      expect(await intentar(token: null, status: 401, mensaje: 'Credenciales inválidas.'), 0);
    });
  });
}
