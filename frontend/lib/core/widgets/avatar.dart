import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/colors.dart';

/// Foto de perfil circular. Si no hay [foto] (URL completa) o no carga,
/// muestra las iniciales sobre un degradado.
class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final bool online;
  final String? foto;
  final Color borde;

  const Avatar({
    super.key,
    required this.name,
    this.size = 56,
    this.online = false,
    this.foto,
    this.borde = Colors.white24,
  });

  static const _palette = [
    [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
    [Color(0xFF8B5CF6), Color(0xFF4C1D95)],
    [Color(0xFF14B8A6), Color(0xFF134E4A)],
    [Color(0xFFF59E0B), Color(0xFF78350F)],
    [Color(0xFFEC4899), Color(0xFF831843)],
  ];

  String get _iniciales {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _iniciadas() {
    final colors = _palette[name.length % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        _iniciales,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final circulo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borde, width: size > 90 ? 3.0 : 1.5),
      ),
      child: ClipOval(
        child: foto == null
            ? _iniciadas()
            : Image.network(
                foto!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _iniciadas(),
              ),
      ),
    );
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          circulo,
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.26,
                height: size * 0.26,
                decoration: BoxDecoration(
                  color: C.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: C.card, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
