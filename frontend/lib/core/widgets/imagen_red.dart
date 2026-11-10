import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:provider/provider.dart';

/// Imagen guardada en el backend. Recibe la ruta tal como viene de la base
/// (`/uploads/...`) y le antepone la dirección del servidor.
class ImagenRed extends StatelessWidget {
  final String? ruta;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData iconoVacio;

  const ImagenRed({
    super.key,
    required this.ruta,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.iconoVacio = Icons.image_outlined,
  });

  Widget _vacio() => Container(
        width: width,
        height: height,
        color: C.card,
        alignment: Alignment.center,
        child: Icon(iconoVacio, color: C.muted, size: 30),
      );

  @override
  Widget build(BuildContext context) {
    final url = context.read<ApiClient>().urlDe(ruta);
    if (url == null) return _vacio();
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => _vacio(),
      loadingBuilder: (context, child, progreso) {
        if (progreso == null) return child;
        return Container(
          width: width,
          height: height,
          color: C.card,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}

/// Atajo para la foto de perfil de alguien a partir de su ruta en la base.
String? urlFoto(BuildContext context, String? ruta) => context.read<ApiClient>().urlDe(ruta);
