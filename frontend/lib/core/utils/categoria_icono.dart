import 'package:flutter/material.dart';

/// Icono según el nombre de la categoría (las categorías viven en la base de datos).
IconData iconoDeCategoria(String nombre) {
  final n = nombre
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');

  const reglas = <String, IconData>{
    'carpint': Icons.carpenter,
    'herrer': Icons.hardware,
    'electric': Icons.bolt,
    'alban': Icons.construction,
    'plomer': Icons.plumbing,
    'fontaner': Icons.plumbing,
    'pintur': Icons.format_paint,
    'jardin': Icons.eco,
  };

  for (final regla in reglas.entries) {
    if (n.contains(regla.key)) return regla.value;
  }
  return Icons.handyman;
}
