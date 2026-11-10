import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manocerca/core/models/filtros_busqueda.dart';
import 'package:manocerca/core/models/mi_servicio.dart';
import 'package:manocerca/core/models/pro.dart';
import 'package:manocerca/core/models/publicacion.dart';
import 'package:manocerca/core/models/resena.dart';
import 'package:manocerca/core/models/solicitud.dart';
import 'package:manocerca/core/utils/texto.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/publicacion_service.dart';
import 'package:manocerca/services/resena_service.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, Object?> _solicitud({String estado = 'Completado', int yaCalifique = 0}) => {
      'id_solicitud': 9,
      'estado': estado,
      'tipo_pago_acordado': 'Día',
      'monto_estimado': '500.00',
      'fecha_solicitud': '2026-10-01 10:00:00',
      'id_categoria': 1,
      'nombre_categoria': 'Carpintería',
      'id_cliente': 7,
      'nombre_cliente': 'Ana',
      'apellido_cliente': 'López',
      'foto_cliente': null,
      'id_trabajador': 20,
      'nombre_trabajador': 'Beto',
      'apellido_trabajador': 'Ruiz',
      'foto_trabajador': '/uploads/imagenes/b.jpg',
      'ya_califique': yaCalifique,
    };

Pro _pro(String nombre, {double? rating, int reviews = 0, double? precio, bool disponible = true, int cat = 1}) =>
    Pro(
      id: nombre.length,
      name: nombre,
      rating: rating,
      reviews: reviews,
      precioBase: precio,
      tipoPago: 'Día',
      idCategoria: cat,
      categoria: cat == 1 ? 'Carpintería' : 'Plomería',
      availability: disponible ? 'Disponible' : 'No disponible',
    );

void main() {
  group('Modelos', () {
    test('Publicacion acepta imágenes como lista o como texto JSON', () {
      final base = {
        'id_publicacion': 3,
        'titulo': 'Mesa para 6',
        'contenido': 'Terminada en 8 días',
        'fecha_creacion': '2026-10-01 09:00:00',
        'id_autor': 20,
        'nombre': 'Beto',
        'apellido': 'Ruiz',
        'total_likes': '4',
        'total_comentarios': 1,
        'me_gusta': 1,
      };
      final lista = Publicacion.fromJson({...base, 'imagenes': ['/uploads/a.jpg', '/uploads/b.jpg']});
      final texto = Publicacion.fromJson({...base, 'imagenes': '["/uploads/a.jpg"]'});

      expect(lista.imagenes, hasLength(2));
      expect(lista.portada, '/uploads/a.jpg');
      expect(lista.totalLikes, 4);
      expect(lista.meGusta, true);
      expect(lista.nombreAutor, 'Beto Ruiz');
      expect(texto.imagenes, ['/uploads/a.jpg']);
      expect(Publicacion.fromJson({...base, 'imagenes': null}).portada, isNull);
    });

    test('Solicitud sabe quién es la otra parte y si falta calificar', () {
      final s = Solicitud.fromJson(_solicitud());
      expect(s.porCalificar, true);
      expect(s.monto, 500);
      expect(s.contraparte(7).nombre, 'Beto Ruiz'); // el cliente ve al trabajador
      expect(s.contraparte(20).nombre, 'Ana López'); // el trabajador ve al cliente
      expect(Solicitud.fromJson(_solicitud(yaCalifique: 1)).porCalificar, false);
      expect(Solicitud.fromJson(_solicitud(estado: 'Aceptado')).porCalificar, false);
    });

    test('ResumenResenas calcula promedio y reparto de estrellas', () {
      Resena r(int c) => Resena(id: c, calificacion: c, idAutor: 1, nombreAutor: 'X');
      final resumen = ResumenResenas.de([r(5), r(5), r(4), r(1)]);
      expect(resumen.total, 4);
      expect(resumen.promedio, closeTo(3.75, 0.001));
      expect(resumen.conteo, [2, 1, 0, 0, 1]);
      expect(ResumenResenas.de(const []).promedio, isNull);
    });

    test('PerfilTrabajador calcula el rango de precios y los oficios', () {
      final p = PerfilTrabajador.fromJson({
        'id_usuario': 20,
        'nombre': 'Beto',
        'apellido': 'Ruiz',
        'disponible': 1,
        'calificacion_promedio': '4.50',
        'total_resenas': 2,
        'servicios': [
          {'id_servicio': 1, 'id_categoria': 1, 'nombre_categoria': 'Carpintería', 'tipo_pago': 'Día', 'precio_base': '800.00'},
          {'id_servicio': 2, 'id_categoria': 1, 'nombre_categoria': 'Carpintería', 'tipo_pago': 'Por hora', 'precio_base': '120.00'},
          {'id_servicio': 3, 'id_categoria': 3, 'nombre_categoria': 'Plomería', 'tipo_pago': 'Destajo', 'precio_base': null},
        ],
      });
      expect(p.nombreCompleto, 'Beto Ruiz');
      expect(p.calificacion, 4.5);
      expect(p.rangoPrecios?.min, 120);
      expect(p.rangoPrecios?.max, 800);
      expect(p.oficios, ['Carpintería', 'Plomería']);
    });
  });

  group('Filtros de búsqueda', () {
    final pros = [
      _pro('Ana López', rating: 4.9, reviews: 30, precio: 500),
      _pro('Beto Ruiz', rating: 3.5, reviews: 2, precio: 200, disponible: false),
      _pro('Carla Díaz', precio: null, cat: 3),
    ];

    test('el texto ignora acentos y mayúsculas', () {
      expect(normalizar('  Plomería '), 'plomeria');
      final r = const FiltrosBusqueda(texto: 'carla diaz').aplicar(pros);
      expect(r.map((p) => p.name), ['Carla Díaz']);
      final porOficio = const FiltrosBusqueda(texto: 'plomeria').aplicar(pros);
      expect(porOficio.map((p) => p.name), ['Carla Díaz']);
    });

    test('combina categoría, calificación, disponibilidad y precio', () {
      expect(const FiltrosBusqueda(idCategoria: 1).aplicar(pros), hasLength(2));
      expect(const FiltrosBusqueda(calificacionMin: 4).aplicar(pros).single.name, 'Ana López');
      expect(const FiltrosBusqueda(soloDisponibles: true).aplicar(pros), hasLength(2));
      expect(const FiltrosBusqueda(precioMax: 300).aplicar(pros).single.name, 'Beto Ruiz');
    });

    test('ordena por precio dejando "a convenir" al final', () {
      final menor = const FiltrosBusqueda(orden: OrdenBusqueda.menorPrecio).aplicar(pros);
      expect(menor.map((p) => p.name), ['Beto Ruiz', 'Ana López', 'Carla Díaz']);
      final mayor = const FiltrosBusqueda(orden: OrdenBusqueda.mayorPrecio).aplicar(pros);
      expect(mayor.map((p) => p.name), ['Ana López', 'Beto Ruiz', 'Carla Díaz']);
    });

    test('cuenta los filtros activos del panel', () {
      expect(const FiltrosBusqueda(texto: 'x', idCategoria: 1).activos, 0);
      const f = FiltrosBusqueda(soloDisponibles: true, calificacionMin: 4, tipoPago: 'Día');
      expect(f.activos, 3);
      expect(f.limpiarPanel().activos, 0);
    });
  });

  group('Servicios', () {
    test('urlDe antepone el servidor a las rutas guardadas', () {
      final api = ApiClient(baseUrl: 'http://10.0.2.2:3001/api');
      expect(api.urlDe('/uploads/imagenes/a.jpg'), 'http://10.0.2.2:3001/uploads/imagenes/a.jpg');
      expect(api.urlDe('https://cdn.x/a.jpg'), 'https://cdn.x/a.jpg');
      expect(api.urlDe(''), isNull);
      expect(api.urlDe(null), isNull);
    });

    test('crear publicación sube cada foto y luego publica con sus rutas', () async {
      final llamadas = <String>[];
      Object? cuerpoPublicacion;
      var n = 0;
      final api = ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((req) async {
          llamadas.add('${req.method} ${req.url.path}');
          if (req.url.path.endsWith('/archivos')) {
            expect(req.headers['content-type'], startsWith('multipart/form-data'));
            expect(latin1.decode(req.bodyBytes), contains('name="archivo"'));
            n++;
            return _json({'ok': true, 'data': {'ruta': '/uploads/imagenes/$n.jpg'}}, 201);
          }
          cuerpoPublicacion = jsonDecode(req.body);
          return _json({'ok': true, 'id_publicacion': 1}, 201);
        }),
      );
      final avance = <int>[];
      await PublicacionService(api).crear(
        titulo: 'Ropero',
        contenido: 'De 2 metros',
        fotos: [
          (bytes: [0xff, 0xd8, 0xff, 1], nombre: 'a.jpg'),
          (bytes: [0xff, 0xd8, 0xff, 2], nombre: 'b.jpg'),
        ],
        alAvanzar: avance.add,
      );

      expect(llamadas, ['POST /api/archivos', 'POST /api/archivos', 'POST /api/publicaciones']);
      expect(avance, [1, 2]);
      expect(cuerpoPublicacion, {
        'titulo': 'Ropero',
        'contenido': 'De 2 metros',
        'imagenes': ['/uploads/imagenes/1.jpg', '/uploads/imagenes/2.jpg'],
      });
    });

    test('calificar manda la solicitud, las estrellas y el comentario', () async {
      Object? cuerpo;
      final api = ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((req) async {
          expect('${req.method} ${req.url.path}', 'POST /api/resenas');
          cuerpo = jsonDecode(req.body);
          return _json({'ok': true, 'id_resena': 1}, 201);
        }),
      );
      await ResenaService(api).calificar(idSolicitud: 9, calificacion: 5, comentario: '  Puntual ');
      expect(cuerpo, {'id_solicitud': 9, 'calificacion': 5, 'comentario': 'Puntual'});

      await ResenaService(api).calificar(idSolicitud: 9, calificacion: 3, comentario: ' ');
      expect(cuerpo, {'id_solicitud': 9, 'calificacion': 3});
    });
  });
}
