import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/colors.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: C.bg,
        colorScheme: const ColorScheme.dark(primary: C.primary, surface: C.bg),
        appBarTheme: const AppBarTheme(
          backgroundColor: C.bg,
          elevation: 0,
          centerTitle: true,
        ),
        useMaterial3: true,
      );
}

/// Decoración estándar de tarjetas.
BoxDecoration cardDeco([double r = 16]) => BoxDecoration(
      color: C.card,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: C.border, width: 1),
    );

/// Decoración estándar de campos de texto.
InputDecoration inputDeco(String hint, {Widget? prefix}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: C.muted, fontSize: 14),
      prefixIcon: prefix,
      filled: true,
      fillColor: C.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.primary),
      ),
    );
