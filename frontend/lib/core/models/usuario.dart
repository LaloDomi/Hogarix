import 'package:manocerca/core/data/ubicaciones_mx.dart';
import 'package:manocerca/core/utils/json.dart';

class Roles {
  static const int cliente = 1;
  static const int trabajador = 2;
}

class Usuario {
  final int id;
  final String nombre;
  final String apellido;
  final String correo;
  final int idRol;

  // Datos de perfil (llegan de GET /api/auth/perfil; pueden faltar).
  final String? telefono;
  final String? fotoPerfil;
  final String? estadoMx;
  final String? municipio;
  final String? colonia;

  /// 'AAAA-MM-DD'
  final String? fechaNacimiento;
  final String? sexo;
  final int? edad;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.idRol,
    this.telefono,
    this.fotoPerfil,
    this.estadoMx,
    this.municipio,
    this.colonia,
    this.fechaNacimiento,
    this.sexo,
    this.edad,
  });

  bool get esTrabajador => idRol == Roles.trabajador;
  String get nombreCompleto => '$nombre $apellido'.trim();
  String get rolTexto => esTrabajador ? 'Trabajador' : 'Cliente';

  /// Correo, o el teléfono si la cuenta se creó solo con teléfono.
  String get contacto => correo.isNotEmpty ? correo : (telefono ?? '');

  bool get tieneUbicacion => (municipio ?? '').isNotEmpty || (estadoMx ?? '').isNotEmpty;

  /// "Puebla, Pue." o null si no ha elegido ubicación.
  String? get ubicacionTexto => ubicacionCorta(municipio, estadoMx);

  /// Une los datos de perfil a la sesión, sin perder el rol del login.
  Usuario conPerfil(Usuario p) => Usuario(
        id: id,
        nombre: p.nombre.isNotEmpty ? p.nombre : nombre,
        apellido: p.apellido.isNotEmpty ? p.apellido : apellido,
        correo: p.correo.isNotEmpty ? p.correo : correo,
        idRol: idRol,
        telefono: p.telefono ?? telefono,
        fotoPerfil: p.fotoPerfil,
        estadoMx: p.estadoMx,
        municipio: p.municipio,
        colonia: p.colonia,
        fechaNacimiento: p.fechaNacimiento,
        sexo: p.sexo,
        edad: p.edad,
      );

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: (json['id_usuario'] as num).toInt(),
        nombre: (json['nombre'] as String?) ?? '',
        apellido: (json['apellido'] as String?) ?? '',
        correo: (json['correo'] as String?) ?? '',
        idRol: json['id_rol'] == null
            ? (json['nombre_rol'] == 'Trabajador' ? Roles.trabajador : Roles.cliente)
            : enteroJson(json['id_rol'], Roles.cliente),
        telefono: json['telefono'] as String?,
        fotoPerfil: json['foto_perfil'] as String?,
        estadoMx: json['estado_mx'] as String?,
        municipio: json['municipio'] as String?,
        colonia: json['colonia'] as String?,
        fechaNacimiento: (json['fecha_nacimiento'] as String?)?.split('T').first,
        sexo: json['sexo'] as String?,
        edad: json['edad'] == null ? null : enteroJson(json['edad']),
      );
}
