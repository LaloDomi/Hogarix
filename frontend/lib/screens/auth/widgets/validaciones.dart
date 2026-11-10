/// Validaciones compartidas por login, registro y recuperación de cuenta.
library;

final _correoValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool esCorreo(String v) => _correoValido.hasMatch(v.trim());

/// Teléfono de México a 10 dígitos. Acepta espacios, guiones y +52.
/// Devuelve null si no son 10 dígitos.
String? normalizarTelefono(String v) {
  var d = v.replaceAll(RegExp(r'\D'), '');
  if (d.length == 13 && d.startsWith('521')) d = d.substring(3);
  if (d.length == 12 && d.startsWith('52')) d = d.substring(2);
  return d.length == 10 ? d : null;
}

String? validarCorreo(String? v) =>
    esCorreo(v ?? '') ? null : 'Ingresa un correo válido';

String? validarTelefono(String? v) =>
    normalizarTelefono(v ?? '') != null ? null : 'El teléfono debe tener 10 dígitos';

/// Campo único del login: correo o teléfono.
String? validarCorreoOTelefono(String? v) {
  final t = (v ?? '').trim();
  if (t.contains('@')) return esCorreo(t) ? null : 'Ingresa un correo válido';
  if (normalizarTelefono(t) != null) return null;
  return 'Ingresa un correo o teléfono válido';
}

String? validarContrasenaNueva(String? v) =>
    (v ?? '').length < 6 ? 'La contraseña debe tener al menos 6 caracteres' : null;

String? validarCodigo(String? v) =>
    RegExp(r'^\d{6}$').hasMatch((v ?? '').trim()) ? null : 'El código tiene 6 dígitos';
