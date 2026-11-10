import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manocerca/app.dart';
import 'package:manocerca/core/models/evento_agenda.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/providers/categorias_provider.dart';
import 'package:manocerca/services/agenda_service.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:provider/provider.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

String _p(int n) => n.toString().padLeft(2, '0');
String _dia(DateTime d) => '${d.year}-${_p(d.month)}-${_p(d.day)}';

void main() {
  group('Fechas', () {
    test('formatoSql y formatos en español', () {
      final d = DateTime(2026, 3, 5, 9, 7, 4);
      expect(formatoSql(d), '2026-03-05 09:07:04');
      expect(horaTexto(d), '09:07');
      expect(minutosATexto(14 * 60 + 30), '14:30');
      expect(tituloMes(d), 'Marzo 2026');
      expect(fechaCorta(DateTime(2026, 10, 12)), 'lunes 12 de octubre');
      expect(fechaLarga(DateTime(2026, 10, 12)), 'lunes 12 de octubre de 2026');
      expect(diaMesAbreviado(DateTime(2026, 10, 12)), '12 oct');
    });

    test('parseFechaSql respeta la hora de pared y convierte las que traen zona', () {
      final pared = parseFechaSql('2026-03-10 09:30:00');
      expect([pared.hour, pared.minute, pared.isUtc], [9, 30, false]);

      final utc = parseFechaSql('2026-03-10T15:00:00.000Z');
      expect(utc.isUtc, false);
      expect(utc.toUtc(), DateTime.utc(2026, 3, 10, 15));
    });
  });

  group('EventoAgenda', () {
    EventoAgenda evento(String ini, String fin) => EventoAgenda.fromJson({
          'id_evento': 1,
          'titulo': 'Cocina',
          'descripcion': null,
          'fecha_inicio': ini,
          'fecha_fin': fin,
        });

    test('fromJson y rango de texto', () {
      final e = evento('2026-03-10 09:00:00', '2026-03-10 12:30:00');
      expect(e.titulo, 'Cocina');
      expect(e.rangoTexto, '09:00 – 12:30');
      expect(evento('2026-03-10 22:00:00', '2026-03-11 06:00:00').rangoTexto,
          '10 mar 22:00 – 11 mar 06:00');
    });

    test('ocurreEn: mismo día, cruce de medianoche y fin exacto a las 00:00', () {
      final e = evento('2026-03-10 22:00:00', '2026-03-11 06:00:00');
      expect(e.ocurreEn(DateTime(2026, 3, 10)), true);
      expect(e.ocurreEn(DateTime(2026, 3, 11)), true);
      expect(e.ocurreEn(DateTime(2026, 3, 12)), false);

      final justo = evento('2026-03-10 20:00:00', '2026-03-11 00:00:00');
      expect(justo.ocurreEn(DateTime(2026, 3, 10)), true);
      expect(justo.ocurreEn(DateTime(2026, 3, 11)), false);
    });
  });

  test('AgendaService manda rango y cuerpos en el formato del backend', () async {
    final llamadas = <String>[];
    final consultas = <Map<String, String>>[];
    final cuerpos = <Object?>[];
    final api = ApiClient(
      baseUrl: 'http://test/api',
      httpClient: MockClient((req) async {
        llamadas.add('${req.method} ${req.url.path}');
        consultas.add(req.url.queryParameters);
        cuerpos.add(req.body.isEmpty ? null : jsonDecode(req.body));
        return _json({'ok': true, 'data': []});
      }),
    );
    final s = AgendaService(api);

    await s.listar(DateTime(2026, 3, 1), DateTime(2026, 4, 5));
    await s.crear(
        titulo: 'Cita', inicio: DateTime(2026, 3, 10, 9), fin: DateTime(2026, 3, 10, 10, 30));
    await s.actualizar(4,
        titulo: 'Cita', inicio: DateTime(2026, 3, 10, 9), fin: DateTime(2026, 3, 10, 11), descripcion: 'x');
    await s.eliminar(4);

    expect(llamadas, [
      'GET /api/agenda',
      'POST /api/agenda',
      'PUT /api/agenda/4',
      'DELETE /api/agenda/4',
    ]);
    expect(consultas[0], {'desde': '2026-03-01 00:00:00', 'hasta': '2026-04-05 00:00:00'});
    expect(cuerpos[1], {
      'titulo': 'Cita',
      'descripcion': null,
      'fecha_inicio': '2026-03-10 09:00:00',
      'fecha_fin': '2026-03-10 10:30:00',
    });
    expect((cuerpos[2] as Map)['descripcion'], 'x');
  });

  group('Pantalla Mi agenda', () {
    late List<Map<String, Object?>> eventos;
    late List<String> peticiones;
    late List<Object?> cuerpos;
    late List<Map<String, String>> consultas;
    late DateTime hoy;

    ApiClient construirApi({int rol = 2}) {
      hoy = DateTime.now();
      eventos = [
        {
          'id_evento': 1,
          'titulo': 'Instalación cocina',
          'descripcion': 'Casa de Ana',
          'fecha_inicio': '${_dia(hoy)} 09:00:00',
          'fecha_fin': '${_dia(hoy)} 12:00:00',
        },
      ];
      peticiones = [];
      cuerpos = [];
      consultas = [];
      return ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((req) async {
          final clave = '${req.method} ${req.url.path}';
          final cuerpo = req.body.isEmpty ? null : jsonDecode(req.body);
          if (req.url.path.contains('/agenda')) {
            peticiones.add(clave);
            cuerpos.add(cuerpo);
            consultas.add(req.url.queryParameters);
          }

          if (clave == 'POST /api/auth/login') {
            return _json({
              'ok': true,
              'token': 'tkn',
              'usuario': {
                'id_usuario': 7,
                'nombre': 'Juan',
                'apellido': 'Pérez',
                'correo': 'juan@test.com',
                'id_rol': rol,
              },
            });
          }
          if (req.url.path.endsWith('/categorias')) return _json({'ok': true, 'data': []});
          if (clave == 'GET /api/agenda') return _json({'ok': true, 'data': eventos});
          if (clave == 'POST /api/agenda') {
            final c = cuerpo as Map<String, dynamic>;
            if (c['titulo'] == 'Choque') {
              return _json(
                  {'ok': false, 'mensaje': 'Ya tienes un evento que se traslapa en ese horario.'},
                  409);
            }
            eventos.add({
              'id_evento': 2,
              'titulo': c['titulo'],
              'descripcion': c['descripcion'],
              'fecha_inicio': c['fecha_inicio'],
              'fecha_fin': c['fecha_fin'],
            });
            return _json({'ok': true, 'id_evento': 2}, 201);
          }
          if (req.method == 'DELETE' && req.url.path.contains('/agenda/')) {
            final id = int.parse(req.url.path.split('/').last);
            eventos.removeWhere((e) => e['id_evento'] == id);
            return _json({'ok': true});
          }
          return _json({'ok': false, 'mensaje': 'No encontrado'}, 404);
        }),
      );
    }

    Future<void> abrirAgenda(WidgetTester tester, ApiClient api) async {
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

    testWidgets('un cliente no ve "Mi agenda"', (tester) async {
      await abrirAgenda(tester, construirApi(rol: 1));
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.text('Mi agenda'), findsNothing);
    });

    testWidgets('muestra el mes, el evento del día y la vista agenda', (tester) async {
      await abrirAgenda(tester, construirApi());
      await tester.tap(find.text('Mi agenda'));
      await tester.pumpAndSettle();

      expect(find.text(tituloMes(hoy)), findsOneWidget);
      expect(find.text('Instalación cocina'), findsOneWidget);
      expect(find.text('09:00 – 12:00'), findsOneWidget);
      expect(find.text(capitalizada(fechaCorta(hoy))), findsOneWidget);

      // La consulta cubre toda la cuadrícula visible del mes
      final desde = DateTime.parse(consultas.first['desde']!.replaceFirst(' ', 'T'));
      final hasta = DateTime.parse(consultas.first['hasta']!.replaceFirst(' ', 'T'));
      expect(desde.weekday, DateTime.monday);
      expect(hasta.difference(desde).inDays % 7, 0);
      expect(!desde.isAfter(DateTime(hoy.year, hoy.month, 1)), true);
      expect(hasta.isAfter(DateTime(hoy.year, hoy.month + 1, 0)), true);

      // Misma información en la vista "Agenda"
      await tester.tap(find.text('Agenda'));
      await tester.pumpAndSettle();
      expect(find.text('Instalación cocina'), findsOneWidget);
      expect(find.text(capitalizada(fechaCorta(hoy))), findsOneWidget);
    });

    testWidgets('agrega un evento, muestra el conflicto de horario y elimina', (tester) async {
      await abrirAgenda(tester, construirApi());
      await tester.tap(find.text('Mi agenda'));
      await tester.pumpAndSettle();

      // Agregar
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar evento'));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo evento'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Revisión eléctrica');

      await tester.tap(find.byKey(const ValueKey('hora-inicio')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10:00').last);
      await tester.pumpAndSettle();

      // Al subir el inicio, el fin se ajusta solo a una hora después
      await tester.tap(find.byKey(const ValueKey('hora-fin-660')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12:00').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar evento'));
      await tester.pumpAndSettle();

      final iPost = peticiones.lastIndexOf('POST /api/agenda');
      expect(cuerpos[iPost], {
        'titulo': 'Revisión eléctrica',
        'descripcion': null,
        'fecha_inicio': '${_dia(hoy)} 10:00:00',
        'fecha_fin': '${_dia(hoy)} 12:00:00',
      });
      expect(find.text('Evento agregado'), findsOneWidget);
      expect(find.text('Revisión eléctrica'), findsOneWidget);
      expect(find.text('10:00 – 12:00'), findsOneWidget);

      // Conflicto de horario: el mensaje del backend se muestra y no se cierra el formulario
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar evento'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Choque');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar evento'));
      await tester.pumpAndSettle();
      expect(find.text('Ya tienes un evento que se traslapa en ese horario.'), findsOneWidget);
      expect(find.text('Nuevo evento'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Eliminar el primero
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(peticiones, contains('DELETE /api/agenda/1'));
      expect(find.text('Instalación cocina'), findsNothing);
      expect(find.text('Revisión eléctrica'), findsOneWidget);
    });

    testWidgets('el formulario pide título y cambia de mes', (tester) async {
      await abrirAgenda(tester, construirApi());
      await tester.tap(find.text('Mi agenda'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar evento'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar evento'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe un título'), findsOneWidget);
      expect(peticiones.where((p) => p.startsWith('POST')), isEmpty);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Mes siguiente: título nuevo, otra consulta, sin eventos de hoy
      final siguiente = DateTime(hoy.year, hoy.month + 1);
      final antes = consultas.length;
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text(tituloMes(siguiente)), findsOneWidget);
      expect(consultas.length, greaterThan(antes));
      expect(find.text('No tienes eventos este día.'), findsOneWidget);
    });
  });
}
