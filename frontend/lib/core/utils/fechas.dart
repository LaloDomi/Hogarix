const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

const _dias = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
];

String _dos(int n) => n.toString().padLeft(2, '0');

String capitalizada(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

/// "Octubre 2026"
String tituloMes(DateTime d) => '${capitalizada(_meses[d.month - 1])} ${d.year}';

/// "lunes 12 de octubre"
String fechaCorta(DateTime d) => '${_dias[d.weekday - 1]} ${d.day} de ${_meses[d.month - 1]}';

/// "lunes 12 de octubre de 2026"
String fechaLarga(DateTime d) => '${fechaCorta(d)} de ${d.year}';

/// "9 oct"
String diaMesAbreviado(DateTime d) => '${d.day} ${_meses[d.month - 1].substring(0, 3)}';

/// "09:30"
String horaTexto(DateTime d) => '${_dos(d.hour)}:${_dos(d.minute)}';

/// 570 -> "09:30"
String minutosATexto(int minutos) => '${_dos(minutos ~/ 60)}:${_dos(minutos % 60)}';

/// Formato que entiende el backend: "2026-10-12 09:30:00".
String formatoSql(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_dos(d.month)}-${_dos(d.day)} '
    '${_dos(d.hour)}:${_dos(d.minute)}:${_dos(d.second)}';

DateTime soloDia(DateTime d) => DateTime(d.year, d.month, d.day);

bool mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Interpreta una fecha del backend. El texto "2026-10-12 09:30:00" es hora de
/// pared (se deja tal cual); si llegara con zona ("...Z") se pasa a hora local.
DateTime parseFechaSql(String texto) {
  final fecha = DateTime.parse(texto.trim().replaceFirst(' ', 'T'));
  return fecha.isUtc ? fecha.toLocal() : fecha;
}

/// "Hace 5 min", "Hace 3 días", "12 oct 2025"…
String haceCuanto(DateTime fecha, {DateTime? ahora}) {
  final diff = (ahora ?? DateTime.now()).difference(fecha);
  if (diff.inMinutes < 1) return 'Justo ahora';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'Ayer';
  if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
  if (diff.inDays < 30) {
    final s = diff.inDays ~/ 7;
    return s == 1 ? 'Hace 1 semana' : 'Hace $s semanas';
  }
  return '${diaMesAbreviado(fecha)} ${fecha.year}';
}
