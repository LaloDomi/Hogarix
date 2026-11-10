import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/core/widgets/rating.dart';

/// Parte superior del perfil (diseño Figma): portada, foto circular que se
/// monta sobre la portada, calificación, "Editar perfil" y nombre.
class CabeceraPerfil extends StatelessWidget {
  final String nombre;
  final String? foto;
  final String? portada;
  final double? calificacion;
  final bool esPropio;
  final bool mostrarAtras;
  final bool? favorito;
  final VoidCallback? onFavorito;
  final VoidCallback onCompartir;
  final VoidCallback? onEditar;

  const CabeceraPerfil({
    super.key,
    required this.nombre,
    required this.onCompartir,
    this.foto,
    this.portada,
    this.calificacion,
    this.esPropio = false,
    this.mostrarAtras = true,
    this.favorito,
    this.onFavorito,
    this.onEditar,
  });

  static const _altoPortada = 170.0;
  static const _tamFoto = 112.0;

  Widget _botonRedondo({required IconData icono, required VoidCallback onTap, Color? color}) {
    return Material(
      color: const Color(0x66000000),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icono, size: 20, color: color ?? Colors.white),
        ),
      ),
    );
  }

  Widget _portada() {
    if (portada != null) {
      return ImagenRed(ruta: portada, height: _altoPortada, width: double.infinity);
    }
    return Container(
      height: _altoPortada,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E4FA8), Color(0xFF0F2A57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Stack(
        children: [
          Positioned(right: -10, top: 10, child: Icon(Icons.handyman, size: 130, color: Color(0x22FFFFFF))),
          Positioned(left: 20, bottom: 18, child: Icon(Icons.construction, size: 60, color: Color(0x14FFFFFF))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: _altoPortada + _tamFoto / 2 + 14,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _portada(),
              // Oscurece el borde inferior para que la foto resalte.
              Positioned(
                left: 0,
                right: 0,
                top: _altoPortada - 60,
                height: 60,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x00000000), Color(0x88000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              if (mostrarAtras)
                Positioned(
                  left: 12,
                  top: 10,
                  child: _botonRedondo(
                    icono: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.maybePop(context),
                  ),
                ),
              Positioned(
                right: 12,
                top: 10,
                child: Row(
                  children: [
                    if (favorito != null && onFavorito != null) ...[
                      _botonRedondo(
                        icono: favorito! ? Icons.favorite : Icons.favorite_border,
                        color: favorito! ? Colors.redAccent : Colors.white,
                        onTap: onFavorito!,
                      ),
                      const SizedBox(width: 8),
                    ],
                    _botonRedondo(icono: Icons.share, onTap: onCompartir),
                  ],
                ),
              ),
              Positioned(
                top: _altoPortada - _tamFoto / 2 - 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Avatar(
                    name: nombre,
                    foto: urlFoto(context, foto),
                    size: _tamFoto,
                    borde: C.bg,
                  ),
                ),
              ),
              Positioned(
                top: _altoPortada + _tamFoto / 2 - 22,
                left: 0,
                right: 0,
                child: Center(child: RatingChip(rating: calificacion)),
              ),
              if (esPropio && onEditar != null)
                Positioned(
                  right: 12,
                  top: _altoPortada + _tamFoto / 2 - 30,
                  child: TextButton.icon(
                    onPressed: onEditar,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    icon: const Icon(Icons.edit, size: 15),
                    label: const Text('Editar perfil'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Barra de pestañas del perfil: "Trabajos", "Rango de precios", "Reseñas".
class PestanasPerfil extends StatelessWidget {
  final List<String> titulos;
  final int actual;
  final ValueChanged<int> onCambiar;
  const PestanasPerfil({
    super.key,
    required this.titulos,
    required this.actual,
    required this.onCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.bg2,
      child: Row(
        children: [
          for (int i = 0; i < titulos.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onCambiar(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: actual == i ? C.navy : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: actual == i ? C.primary : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Text(
                    titulos[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: actual == i ? Colors.white : C.muted,
                      fontWeight: actual == i ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
