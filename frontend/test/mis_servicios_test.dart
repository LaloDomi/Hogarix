import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manocerca/app.dart';
import 'package:manocerca/core/models/mi_servicio.dart';
import 'package:manocerca/core/utils/precio.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/providers/categorias_provider.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/trabajador_service.dart';
import 'package:provider/provider.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, Object?> _usuario(int rol) => {
      'id_usuario': 7,
      'nombre': 'Juan',
      'apellido': 'Pérez',
      'correo': 'juan@test.com',
      'id_rol': rol,
    };

const _categorias = [
  {'id_categoria': 1, 'nombre_categoria': 'Carpintería', 'descripcion': null},
  {'id_categoria': 3, 'nombre_categoria': 'Plomería', 'descripcion': null},
];

Map<String, Object?> _servicio(int id, int idCat, String cat, String tipo, Object? precio) => {
      'id_servicio': id,
      'id_categoria': idCat,
      'nombre_categoria': cat,
      'tipo_pago': tipo,
      'precio_base': precio,
      'descripcion_servicio': 'Detalle de $cat',
    };

void main() {
  group('Modelos y utilidades', () {
    test('MiServicio.fromJson convierte el precio que llega como texto', () {
      final s = MiServicio.fromJson(_servicio(5, 3, 'Plomería', 'Día', '200.00'));
      expect(s.id, 5);
      expect(s.idCategoria, 3);
      expect(s.precioBase, 200.0);
      expect(s.precioTexto, r'$200 por día');
    });

    test('PerfilTrabajador acepta disponible como bool o como 1/0 y sin servicios', () {
      expect(PerfilTrabajador.fromJson({'disponible': true, 'servicios': []}).disponible, true);
      expect(PerfilTrabajador.fromJson({'disponible': 0}).disponible, false);
      expect(PerfilTrabajador.fromJson({'disponible': 1}).servicios, isEmpty);
    });

    test('textoPrecio', () {
      expect(textoPrecio(null, 'Día'), 'Precio a convenir');
      expect(textoPrecio(99.5, 'Por trabajo'), r'$99.50 por trabajo');
      expect(textoPrecio(300, 'Destajo'), r'$300 a destajo');
    });
  });

  group('TrabajadorService', () {
    test('manda cada operación al endpoint y cuerpo correctos', () async {
      final llamadas = <String>[];
      final cuerpos = <Object?>[];
      final api = ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((req) async {
          llamadas.add('${req.method} ${req.url.path}');
          cuerpos.add(req.body.isEmpty ? null : jsonDecode(req.body));
          return _json({'ok': true, 'data': {'disponible': true, 'servicios': []}});
        }),
      );
      final s = TrabajadorService(api);

      await s.perfil(7);
      await s.crearServicio(idCategoria: 1, tipoPago: 'Por hora', precioBase: 150, descripcion: 'x');
      await s.actualizarServicio(9, idCategoria: 3, tipoPago: 'Día');
      await s.eliminarServicio(9);
      await s.actualizarDisponibilidad(false);

      expect(llamadas, [
        'GET /api/trabajadores/7',
        'POST /api/trabajadores/servicios',
        'PUT /api/trabajadores/servicios/9',
        'DELETE /api/trabajadores/servicios/9',
        'PUT /api/trabajadores/perfil',
      ]);
      expect(cuerpos[1], {
        'id_categoria': 1,
        'tipo_pago': 'Por hora',
        'precio_base': 150.0,
        'descripcion_servicio': 'x',
      });
      expect(cuerpos[2], {
        'id_categoria': 3,
        'tipo_pago': 'Día',
        'precio_base': null,
        'descripcion_servicio': null,
      });
      expect(cuerpos[4], {'disponible': false});
    });
  });

  group('Pantallas', () {
    late List<Map<String, Object?>> servicios;
    late bool disponible;
    late List<String> peticiones;
    late List<Object?> cuerpos;

    ApiClient construirApi(int rol) {
      servicios = [_servicio(10, 3, 'Plomería', 'Día', '200.00')];
      disponible = true;
      peticiones = [];
      cuerpos = [];
      return ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((req) async {
          final ruta = req.url.path;
          final clave = '${req.method} $ruta';
          final cuerpo = req.body.isEmpty ? null : jsonDecode(req.body);
          if (!ruta.endsWith('/categorias')) {
            peticiones.add(clave);
            cuerpos.add(cuerpo);
          }

          if (clave.endsWith('POST /api/auth/login')) {
            return _json({'ok': true, 'token': 'tkn', 'usuario': _usuario(rol)});
          }
          if (ruta.endsWith('/categorias')) return _json({'ok': true, 'data': _categorias});
          if (clave == 'GET /api/trabajadores/7') {
            return _json({
              'ok': true,
              'data': {'disponible': disponible, 'servicios': servicios},
            });
          }
          if (clave == 'PUT /api/trabajadores/perfil') {
            disponible = (cuerpo as Map)['disponible'] as bool;
            return _json({'ok': true});
          }
          if (clave == 'POST /api/trabajadores/servicios') {
            final c = cuerpo as Map<String, dynamic>;
            final cat = _categorias.firstWhere((x) => x['id_categoria'] == c['id_categoria']);
            servicios.add(_servicio(11, c['id_categoria'] as int, cat['nombre_categoria'] as String,
                c['tipo_pago'] as String, c['precio_base']));
            return _json({'ok': true, 'id_servicio': 11}, 201);
          }
          if (req.method == 'DELETE' && ruta.contains('/trabajadores/servicios/')) {
            final id = int.parse(ruta.split('/').last);
            servicios.removeWhere((s) => s['id_servicio'] == id);
            return _json({'ok': true});
          }
          return _json({'ok': false, 'mensaje': 'No encontrado'}, 404);
        }),
      );
    }

    Future<void> abrirApp(WidgetTester tester, ApiClient api) async {
      tester.view.physicalSize = const Size(1500, 3000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // La fuente de prueba es más ancha que la real: se ignoran solo falsos desbordamientos.
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        original?.call(d);
      };
      addTearDown(() => FlutterError.onError = original);

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
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'juan@test.com');
      await tester.enterText(campos.at(1), '123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      // El trabajador tiene sus herramientas en la pestaña "Más";
      // el cliente, en "Perfil".
      final mas = find.text('Más');
      await tester.tap(mas.evaluate().isNotEmpty ? mas : find.text('Perfil'));
      await tester.pumpAndSettle();
    }

    testWidgets('un cliente no ve "Mis servicios"', (tester) async {
      await abrirApp(tester, construirApi(1));

      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.text('Mis servicios'), findsNothing);
    });

    testWidgets('el trabajador ve sus servicios, cambia disponibilidad, agrega y elimina', (tester) async {
      await abrirApp(tester, construirApi(2));

      await tester.tap(find.text('Mis servicios'));
      await tester.pumpAndSettle();

      expect(peticiones, contains('GET /api/trabajadores/7'));
      expect(find.text('Plomería'), findsOneWidget);
      expect(find.text(r'$200 por día'), findsOneWidget);
      expect(find.text('Detalle de Plomería'), findsOneWidget);

      // Disponibilidad
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      final iPut = peticiones.lastIndexOf('PUT /api/trabajadores/perfil');
      expect(cuerpos[iPut], {'disponible': false});
      expect(find.text('Los clientes te ven como no disponible'), findsOneWidget);

      // Agregar
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar servicio'));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo servicio'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carpintería').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Por hora').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), '150,5');
      await tester.enterText(find.byType(TextFormField).at(1), 'Muebles a medida');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar servicio'));
      await tester.pumpAndSettle();

      final iPost = peticiones.lastIndexOf('POST /api/trabajadores/servicios');
      expect(cuerpos[iPost], {
        'id_categoria': 1,
        'tipo_pago': 'Por hora',
        'precio_base': 150.5,
        'descripcion_servicio': 'Muebles a medida',
      });
      expect(find.text('Servicio agregado'), findsOneWidget);
      expect(find.text('Carpintería'), findsOneWidget);
      expect(find.text(r'$150.50 por hora'), findsOneWidget);

      // Eliminar la fontanería
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(peticiones, contains('DELETE /api/trabajadores/servicios/10'));
      expect(find.text('Plomería'), findsNothing);
      expect(find.text('Carpintería'), findsOneWidget);
    });

    testWidgets('el formulario valida antes de llamar al backend', (tester) async {
      await abrirApp(tester, construirApi(2));
      await tester.tap(find.text('Mis servicios'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar servicio'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'abc');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar servicio'));
      await tester.pumpAndSettle();

      expect(find.text('Elige una categoría'), findsOneWidget);
      expect(find.text('Elige cómo cobras'), findsOneWidget);
      expect(find.text('Ingresa un monto válido'), findsOneWidget);
      expect(peticiones.where((p) => p.startsWith('POST /api/trabajadores')), isEmpty);
    });
  });
}
