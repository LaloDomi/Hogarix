import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/colors.dart';

class Stars extends StatelessWidget {
  final double rating;
  final double size;
  const Stars({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData icon;
        if (rating >= i + 1) {
          icon = Icons.star_rounded;
        } else if (rating > i + 0.4) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, size: size, color: C.star);
      }),
    );
  }
}
