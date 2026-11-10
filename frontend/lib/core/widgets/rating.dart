import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/colors.dart';

/// Pastilla "⭐ 4.8" como la del diseño (bajo la foto del perfil).
class RatingChip extends StatelessWidget {
  final double? rating;
  final bool claro;
  const RatingChip({super.key, required this.rating, this.claro = true});

  @override
  Widget build(BuildContext context) {
    final texto = rating == null ? 'Nuevo' : rating!.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: claro ? C.cardLight : C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: claro ? Colors.white : C.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: C.star, size: 16),
          const SizedBox(width: 4),
          Text(texto,
              style: TextStyle(
                color: claro ? C.textDark : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

/// Fila de 5 estrellas grandes para elegir una calificación.
class SelectorEstrellas extends StatelessWidget {
  final int valor;
  final ValueChanged<int> onChanged;
  final double size;
  const SelectorEstrellas({
    super.key,
    required this.valor,
    required this.onChanged,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 1; i <= 5; i++)
          IconButton(
            key: ValueKey('estrella-$i'),
            iconSize: size,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            constraints: const BoxConstraints(),
            onPressed: () => onChanged(i),
            icon: AnimatedScale(
              scale: i <= valor ? 1.0 : 0.88,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                i <= valor ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i <= valor ? C.star : C.muted,
              ),
            ),
          ),
      ],
    );
  }
}

/// Texto que acompaña a cada número de estrellas.
String textoCalificacion(int estrellas) => switch (estrellas) {
      1 => 'Muy mala',
      2 => 'Mala',
      3 => 'Regular',
      4 => 'Buena',
      5 => 'Excelente',
      _ => 'Toca una estrella',
    };
