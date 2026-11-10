import 'dart:convert';

import 'package:manocerca/core/utils/fechas.dart';

/// Ayudas para leer las respuestas del backend. MySQL entrega los DECIMAL y
/// algunos COUNT como texto ("150.00"), y los booleanos como 0/1.

double? numeroJson(Object? valor) => valor == null ? null : double.tryParse('$valor');

int enteroJson(Object? valor, [int defecto = 0]) =>
    valor is num ? valor.toInt() : (int.tryParse('$valor') ?? defecto);

bool boolJson(Object? valor) => valor == true || valor == 1 || valor == '1';

DateTime? fechaJson(Object? valor) {
  if (valor is! String || valor.trim().isEmpty) return null;
  try {
    return parseFechaSql(valor);
  } catch (_) {
    return null;
  }
}

/// Lista de textos que puede llegar como lista JSON o como texto con JSON.
List<String> listaTextosJson(Object? valor) {
  Object? lista = valor;
  if (valor is String) {
    try {
      lista = jsonDecode(valor);
    } catch (_) {
      return const [];
    }
  }
  if (lista is! List) return const [];
  return [for (final e in lista) if (e != null && '$e'.isNotEmpty) '$e'];
}
