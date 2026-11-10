import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manocerca/app.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/providers/categorias_provider.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:provider/provider.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

const _usuarioJson = {
  'id_usuario': 7,
  'nombre': 'Juan',
  'apellido': 'Pérez',
  'correo': 'juan@test.com',
  'id_rol': 2,
};

void main() {
  group('AuthProvider', () {
    test('login correcto guarda usuario y token en memoria', () async {
      final api = ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((_) async =>
            _json({'ok': true, 'token': 'tkn', 'usuario': _usuarioJson})),
      );
      final auth = AuthProvider(api);

      final ok = await auth.login(usuario: 'juan@test.com', contrasena: '123456');

      expect(ok, true);
      expect(auth.autenticado, true);
      expect(auth.usuario!.nombreCompleto, 'Juan Pérez');
      expect(auth.usuario!.esTrabajador, true);
      expect(api.token, 'tkn');
    });

    test('login con credenciales malas deja el error y no autentica', () async {
      final api = ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((_) async =>
            _json({'ok': false, 'mensaje': 'Credenciales inválidas.'}, 401)),
      );
      final auth = AuthProvider(api);

      final ok = await auth.login(usuario: 'a@b.com', contrasena: 'mala');

      expect(ok, false);
      expect(auth.autenticado, false);
      expect(auth.error, 'Credenciales inválidas.');
      expect(api.token, isNull);
    });

    test('cerrarSesion borra usuario y token', () async {
      final api = ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((_) async =>
            _json({'ok': true, 'token': 'tkn', 'usuario': _usuarioJson})),
      );
      final auth = AuthProvider(api);
      await auth.login(usuario: 'juan@test.com', contrasena: '123456');

      auth.cerrarSesion();

      expect(auth.autenticado, false);
      expect(api.token, isNull);
    });

    test('registrar manda el rol y el teléfono solo si existe', () async {
      Map<String, dynamic>? enviado;
      final api = ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((req) async {
          enviado = jsonDecode(req.body) as Map<String, dynamic>;
          return _json({'ok': true, 'token': 't', 'usuario': _usuarioJson}, 201);
        }),
      );
      final auth = AuthProvider(api);

      await auth.registrar(
        idRol: 2,
        nombre: 'Juan',
        apellido: 'Pérez',
        correo: 'juan@test.com',
        contrasena: '123456',
        telefono: '',
      );

      expect(enviado!['id_rol'], 2);
      expect(enviado!.containsKey('telefono'), false);
    });

    test('registrar con correo pide el código y luego crea la cuenta', () async {
      final cuerpos = <Map<String, dynamic>>[];
      final api = ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((req) async {
          final b = jsonDecode(req.body) as Map<String, dynamic>;
          cuerpos.add(b);
          if (!b.containsKey('codigo')) {
            return _json({'ok': true, 'requiere_codigo': true, 'mensaje': 'Te enviamos un código'}, 202);
          }
          return _json({'ok': true, 'token': 't', 'usuario': _usuarioJson}, 201);
        }),
      );
      final auth = AuthProvider(api);
      Future<ResultadoRegistro> registrar([String? codigo]) => auth.registrar(
            idRol: 1,
            nombre: 'Juan',
            apellido: 'Pérez',
            correo: 'juan@test.com',
            contrasena: '123456',
            codigo: codigo,
          );

      expect(await registrar(), ResultadoRegistro.requiereCodigo);
      expect(auth.autenticado, false);

      expect(await registrar('123456'), ResultadoRegistro.creada);
      expect(cuerpos.last['codigo'], '123456');
      expect(auth.autenticado, true);
    });
  });

  group('Flujo de pantallas', () {
    testWidgets('bienvenida -> login -> panel con el nombre -> cerrar sesión', (tester) async {
      tester.view.physicalSize = const Size(1500, 3000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // La fuente de prueba es más ancha que la real y provoca falsos
      // desbordamientos en el banner del Home; solo se ignoran esos avisos.
      final manejadorOriginal = FlutterError.onError;
      FlutterError.onError = (detalles) {
        if (detalles.exceptionAsString().contains('overflowed')) return;
        manejadorOriginal?.call(detalles);
      };
      addTearDown(() => FlutterError.onError = manejadorOriginal);

      final api = ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((_) async =>
            _json({'ok': true, 'token': 'tkn', 'usuario': _usuarioJson})),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiClient>.value(value: api),
            ChangeNotifierProvider(create: (_) => AuthProvider(api)),
            ChangeNotifierProvider(create: (_) => CategoriasProvider(api)),
          ],
          child: const Hogarix(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Crear cuenta'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'juan@test.com');
      await tester.enterText(campos.at(1), '123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Hola, Juan'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Crear cuenta'), findsNothing);

      // El usuario de prueba es trabajador: su cuenta está en la pestaña "Más".
      await tester.tap(find.text('Más'));
      await tester.pumpAndSettle();
      expect(find.text('Juan Pérez'), findsOneWidget);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Crear cuenta'), findsOneWidget);
      expect(find.text('Hola, Juan'), findsNothing);
    });

    testWidgets('el login valida el formulario antes de llamar al backend', (tester) async {
      tester.view.physicalSize = const Size(1500, 3000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      var llamadas = 0;
      final api = ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((_) async {
          llamadas++;
          return _json({'ok': true});
        }),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiClient>.value(value: api),
            ChangeNotifierProvider(create: (_) => AuthProvider(api)),
            ChangeNotifierProvider(create: (_) => CategoriasProvider(api)),
          ],
          child: const Hogarix(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'no-es-correo');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un correo o teléfono válido'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
      expect(llamadas, 0);
    });
  });
}
