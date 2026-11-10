import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manocerca/core/data/ubicaciones_mx.dart';
import 'package:manocerca/core/models/conversacion.dart';
import 'package:manocerca/core/models/filtros_busqueda.dart';
import 'package:manocerca/core/models/pro.dart';
import 'package:manocerca/core/models/solicitud.dart';
import 'package:manocerca/core/models/usuario.dart';
import 'package:manocerca/core/models/visita.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/visita_service.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, Object?> _visita({String estado = 'Propuesta', int porMi = 0}) => {
      'id_visita': 3,
      'id_solicitud': 9,
      'fecha_inicio': '2026-11-02 10:00:00',
      'fecha_fin': '2026-11-02 12:30:00',
      'direccion': 'Calle 5 #20',
      'notas': null,
      'estado': estado,
      'propuesta_por_mi': porMi,
      'nombre_categoria': 'Plomería',
      'id_cliente': 7,
      'nombre_cliente': 'Ana',
      'apellido_cliente': 'López',
      'id_trabajador': 20,
      'nombre_trabajador': 'Beto',
      'apellido_trabajador': 'Ruiz',
    };

void main() {
  group('Ubicación', () {
    test('ubicacionCorta abrevia el estado', () {
      expect(ubicacionCorta('Puebla', 'Puebla'), 'Puebla, Pue.');
      expect(ubicacionCorta('Coyoacán', 'Ciudad de México'), 'Coyoacán, CDMX');
      expect(ubicacionCorta(null, 'Jalisco'), 'Jalisco');
      expect(ubicacionCorta('', ''), isNull);
      expect(ubicacionesMx, hasLength(32));
    });

    test('Usuario lee el perfil completo y conserva el rol del login', () {
      final login = Usuario.fromJson(
          {'id_usuario': 7, 'nombre': 'Ana', 'apellido': 'López', 'correo': 'a@b.com', 'id_rol': 2});
      final perfil = Usuario.fromJson({
        'id_usuario': 7,
        'nombre': 'Ana',
        'apellido': 'López',
        'correo': 'a@b.com',
        'nombre_rol': 'Cliente',
        'estado_mx': 'Puebla',
        'municipio': 'Atlixco',
        'fecha_nacimiento': '1995-04-10',
        'edad': 31,
      });
      final u = login.conPerfil(perfil);
      expect(u.esTrabajador, true);
      expect(u.ubicacionTexto, 'Atlixco, Pue.');
      expect(u.fechaNacimiento, '1995-04-10');
      expect(u.edad, 31);
      expect(login.tieneUbicacion, false);
    });

    test('la solicitud arma la dirección sugerida del cliente', () {
      final s = Solicitud.fromJson({
        'id_solicitud': 1,
        'estado': 'Aceptado',
        'tipo_pago_acordado': 'Día',
        'id_categoria': 1,
        'nombre_categoria': 'Plomería',
        'id_cliente': 7,
        'nombre_cliente': 'Ana',
        'id_trabajador': 20,
        'nombre_trabajador': 'Beto',
        'estado_cliente': 'Puebla',
        'municipio_cliente': 'Puebla',
        'colonia_cliente': 'Centro',
        'proxima_visita': '2026-11-02 10:00:00',
      });
      expect(s.activa, true);
      expect(s.ubicacionCliente, 'Col. Centro, Puebla, Pue.');
      expect(s.proximaVisita, DateTime(2026, 11, 2, 10));
    });

    test('"En mi zona" filtra por estado y los del mismo municipio van primero', () {
      Pro p(String n, String? edo, String? mun) => Pro(
            id: n.length,
            name: n,
            rating: 4.0,
            availability: 'Disponible',
            estadoMx: edo,
            municipio: mun,
          );
      final pros = [p('Lejos', 'Jalisco', 'Guadalajara'), p('Estado', 'Puebla', 'Atlixco'), p('Cerca', 'Puebla', 'Puebla')];
      const base = FiltrosBusqueda(miEstado: 'Puebla', miMunicipio: 'Puebla');
      expect(base.aplicar(pros).first.name, 'Cerca');
      expect(base.aplicar(pros).last.name, 'Lejos');
      final zona = base.copyWith(soloMiZona: true);
      expect(zona.aplicar(pros).map((x) => x.name), ['Cerca', 'Estado']);
      expect(zona.activos, 1);
    });
  });

  group('Visitas', () {
    test('Visita sabe a quién le toca confirmar y en qué día ocurre', () {
      final propuesta = Visita.fromJson(_visita());
      expect(propuesta.esperaMiConfirmacion, true);
      expect(propuesta.rangoTexto, '10:00 – 12:30');
      expect(propuesta.ocurreEn(DateTime(2026, 11, 2)), true);
      expect(propuesta.ocurreEn(DateTime(2026, 11, 3)), false);
      expect(propuesta.contraparte(7).nombre, 'Beto Ruiz');
      expect(Visita.fromJson(_visita(porMi: 1)).esperaMiConfirmacion, false);
      expect(Visita.fromJson(_visita(estado: 'Confirmada')).esperaMiConfirmacion, false);
    });

    test('VisitaService manda fechas en formato del backend', () async {
      final peticiones = <String>[];
      final cuerpos = <Object?>[];
      final api = ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((req) async {
          peticiones.add('${req.method} ${req.url.path}');
          cuerpos.add(req.body.isEmpty ? null : jsonDecode(req.body));
          if (req.method == 'GET') return _json({'ok': true, 'data': [_visita()]});
          return _json({'ok': true}, 201);
        }),
      );
      final s = VisitaService(api);
      final lista = await s.listar(DateTime(2026, 11, 1), DateTime(2026, 12, 1));
      await s.crear(
          idSolicitud: 9, inicio: DateTime(2026, 11, 5, 9), fin: DateTime(2026, 11, 5, 11));
      await s.cambiarEstado(3, EstadoVisita.confirmada);

      expect(lista.single.id, 3);
      expect(peticiones, ['GET /api/visitas', 'POST /api/visitas', 'PATCH /api/visitas/3/estado']);
      expect(cuerpos[1], {
        'id_solicitud': 9,
        'fecha_inicio': '2026-11-05 09:00:00',
        'fecha_fin': '2026-11-05 11:00:00',
        'direccion': '',
        'notas': '',
      });
      expect(cuerpos[2], {'estado': 'Confirmada'});
    });
  });

  group('Chat y sesión', () {
    test('Conversacion arma la vista previa', () {
      final c = Conversacion.fromJson({
        'id_conversacion': 1,
        'id_otro_usuario': 20,
        'nombre_otro_usuario': 'Beto',
        'apellido_otro_usuario': 'Ruiz',
        'ultimo_mensaje': null,
        'ultima_imagen': '/uploads/imagenes/a.jpg',
        'ultimo_es_mio': 1,
        'no_leidos': '2',
      });
      expect(c.vistaPrevia, 'Tú: 📷 Foto');
      expect(c.noLeidos, 2);
    });
  });
}
