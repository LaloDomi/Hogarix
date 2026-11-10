import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manocerca/app.dart';
import 'package:manocerca/core/models/categoria.dart';
import 'package:manocerca/core/models/pro.dart';
import 'package:manocerca/core/utils/categoria_icono.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/providers/categorias_provider.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/servicio_service.dart';
import 'package:provider/provider.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

const _usuario = {
  'id_usuario': 7,
  'nombre': 'Juan',
  'apellido': 'Pérez',
  'correo': 'juan@test.com',
  'id_rol': 1,
};

const _categorias = [
  {'id_categoria': 1, 'nombre_categoria': 'Carpintería', 'descripcion': null},
  {'id_categoria': 4, 'nombre_categoria': 'Electricidad', 'descripcion': 'Instalaciones'},
];

Map<String, dynamic> _servicio({
  int idUsuario = 20,
  String nombre = 'Ana',
  String tipoPago = 'Día',
  Object? precio = '500.00',
}) =>
    {
      'id_servicio': 1,
      'tipo_pago': tipoPago,
      'precio_base': precio,
      'descripcion_servicio': 'Muebles a medida',
      'nombre_categoria': 'Carpintería',
      'id_usuario': idUsuario,
      'nombre': nombre,
      'apellido': 'López',
      'foto_perfil': null,
      'telefono': '5551234567',
    };

ApiClient _api(MockClientHandler h) =>
    ApiClient(baseUrl: 'http://test/api', httpClient: MockClient(h));

void main() {
  group('Modelos', () {
    test('Categoria.fromJson', () {
      final c = Categoria.fromJson(_categorias[1]);
      expect(c.id, 4);
      expect(c.nombre, 'Electricidad');
      expect(c.descripcion, 'Instalaciones');
    });

    test('Pro.fromServicioJson convierte el precio que llega como texto', () {
      final p = Pro.fromServicioJson(_servicio());
      expect(p.id, 20);
      expect(p.name, 'Ana López');
      expect(p.precioBase, 500.0);
      expect(p.rating, isNull);
      expect(p.reviews, 0);
      expect(p.availability, isNull);
      expect(p.categoria, 'Carpintería');
    });

    test('Pro lee calificación y disponibilidad cuando el backend las envía', () {
      final p = Pro.fromServicioJson({
        ..._servicio(),
        'calificacion_promedio': '4.50',
        'total_resenas': 8,
        'disponible': 1,
      });
      expect(p.rating, 4.5);
      expect(p.reviews, 8);
      expect(p.availability, 'Disponible');
    });

    test('precioTexto según tipo de pago', () {
      expect(Pro.fromServicioJson(_servicio()).precioTexto, r'$500 por día');
      expect(
        Pro.fromServicioJson(_servicio(tipoPago: 'Por hora', precio: '150.50')).precioTexto,
        r'$150.50 por hora',
      );
      expect(
        Pro.fromServicioJson(_servicio(tipoPago: 'Destajo', precio: '80.00')).precioTexto,
        r'$80 a destajo',
      );
      expect(Pro.fromServicioJson(_servicio(precio: null)).precioTexto, 'Precio a convenir');
    });

    test('iconoDeCategoria ignora acentos y mayúsculas, con icono por defecto', () {
      expect(iconoDeCategoria('Carpintería'), Icons.carpenter);
      expect(iconoDeCategoria('ALBAÑILERÍA'), Icons.construction);
      expect(iconoDeCategoria('Electricidad'), Icons.bolt);
      expect(iconoDeCategoria('Plomería'), Icons.plumbing);
      expect(iconoDeCategoria('Cerrajería'), Icons.handyman);
    });
  });

  group('Servicios y provider', () {
    test('buscar manda id_categoria y omite tipo_pago cuando es null', () async {
      final urls = <Uri>[];
      final api = _api((req) async {
        urls.add(req.url);
        return _json({'ok': true, 'data': [_servicio()]});
      });
      final servicio = ServicioService(api);

      final todos = await servicio.buscar(idCategoria: 1);
      await servicio.buscar(idCategoria: 1, tipoPago: 'Por hora');

      expect(todos, hasLength(1));
      expect(urls[0].queryParameters, {'id_categoria': '1'});
      expect(urls[1].queryParameters, {'id_categoria': '1', 'tipo_pago': 'Por hora'});
    });

    test('CategoriasProvider carga una sola vez', () async {
      var llamadas = 0;
      final provider = CategoriasProvider(_api((_) async {
        llamadas++;
        return _json({'ok': true, 'data': _categorias});
      }));

      await provider.cargarSiHaceFalta();
      await provider.cargarSiHaceFalta();

      expect(provider.items.map((c) => c.nombre), ['Carpintería', 'Electricidad']);
      expect(llamadas, 1);
    });

    test('CategoriasProvider guarda el error y permite reintentar', () async {
      var falla = true;
      final provider = CategoriasProvider(_api((_) async => falla
          ? _json({'ok': false, 'mensaje': 'Error interno del servidor.'}, 500)
          : _json({'ok': true, 'data': _categorias})));

      await provider.recargar();
      expect(provider.items, isEmpty);
      expect(provider.error, 'Error interno del servidor.');

      falla = false;
      await provider.recargar();
      expect(provider.items, hasLength(2));
      expect(provider.error, isNull);
    });
  });

  testWidgets('Home con categorías reales -> lista -> filtro por tipo de pago', (tester) async {
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

    final busquedas = <Map<String, String>>[];
    final api = _api((req) async {
      final ruta = req.url.path;
      if (ruta.endsWith('/auth/login')) {
        return _json({'ok': true, 'token': 'tkn', 'usuario': _usuario});
      }
      if (ruta.endsWith('/categorias')) {
        return _json({'ok': true, 'total': 2, 'data': _categorias});
      }
      if (ruta.endsWith('/servicios/buscar')) {
        busquedas.add(req.url.queryParameters);
        final tipo = req.url.queryParameters['tipo_pago'];
        if (tipo == 'Destajo') return _json({'ok': true, 'total': 0, 'data': []});
        return _json({
          'ok': true,
          'total': 2,
          'data': [
            _servicio(),
            _servicio(idUsuario: 21, nombre: 'Beto', tipoPago: 'Por hora', precio: '120.00'),
          ],
        });
      }
      return _json({'ok': false, 'mensaje': 'No encontrado'}, 404);
    });

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

    // Categorías que vienen del backend (no las fijas de antes)
    expect(find.text('Carpintería'), findsOneWidget);
    expect(find.text('Electricidad'), findsOneWidget);
    expect(find.text('Jardineros'), findsNothing);

    await tester.tap(find.text('Carpintería'));
    await tester.pumpAndSettle();

    expect(busquedas.last, {'id_categoria': '1'});
    expect(find.text('2 profesionales'), findsOneWidget);
    expect(find.text('Ana López'), findsOneWidget);
    expect(find.text(r'$500 por día'), findsOneWidget);
    expect(find.text(r'$120 por hora'), findsOneWidget);
    expect(find.text('Sin reseñas aún'), findsNWidgets(2));
    // El teléfono que devuelve el backend no se muestra
    expect(find.text('5551234567'), findsNothing);

    await tester.tap(find.text('Destajo'));
    await tester.pumpAndSettle();

    expect(busquedas.last, {'id_categoria': '1', 'tipo_pago': 'Destajo'});
    expect(find.text('Aún no hay profesionales con este filtro.'), findsOneWidget);
    expect(find.text('0 profesionales'), findsOneWidget);
  });
}
