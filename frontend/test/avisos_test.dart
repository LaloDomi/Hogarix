import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manocerca/providers/avisos_provider.dart';
import 'package:manocerca/services/api_client.dart';

http.Response _json(Object body) => http.Response(jsonEncode(body), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  test('avisa solo cuando llega una notificación nueva', () async {
    var total = 1;
    var ultimoId = 10;
    final api = ApiClient(
      baseUrl: 'http://test/api',
      httpClient: MockClient((req) async {
        if (req.url.path.endsWith('/no-leidas')) {
          return _json({'ok': true, 'data': {'total': total}});
        }
        expect(req.url.queryParameters['no_leidas'], 'true');
        return _json({
          'ok': true,
          'data': [
            {'id_notificacion': ultimoId, 'tipo': 'solicitud_nueva', 'titulo': 'Nueva solicitud'},
          ],
        });
      }),
    );
    final avisos = AvisosProvider(api);

    // La primera revisión solo toma la referencia.
    expect(await avisos.revisar(), isNull);
    expect(avisos.noLeidas, 1);

    // Sin cambios: no hay aviso.
    expect(await avisos.revisar(), isNull);

    // Llega otra.
    total = 2;
    ultimoId = 11;
    final nueva = await avisos.revisar();
    expect(nueva?.titulo, 'Nueva solicitud');
    expect(avisos.noLeidas, 2);
  });
}
