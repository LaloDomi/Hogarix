import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/asistente/asistente_screen.dart';
import 'package:manocerca/screens/editar_perfil/editar_perfil_screen.dart';
import 'package:manocerca/screens/ubicacion/ubicacion_sheet.dart';
import 'package:manocerca/screens/main_shell/shell_controller.dart';
import 'package:manocerca/screens/publicaciones/crear_publicacion_screen.dart';
import 'package:manocerca/screens/servicios/mis_servicios_screen.dart';
import 'package:manocerca/screens/solicitudes/solicitudes_screen.dart';
import 'package:provider/provider.dart';

/// Pestaña "Más" del trabajador: cuenta y herramientas de trabajo.
class MasScreen extends StatelessWidget {
  const MasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    if (usuario == null) return const SizedBox.shrink();
    final shell = context.read<ShellController>();

    void abrir(Widget pantalla) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Avatar(
                name: usuario.nombreCompleto,
                foto: urlFoto(context, usuario.fotoPerfil),
                size: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usuario.nombreCompleto,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(usuario.contacto, style: const TextStyle(color: C.muted, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: cardDeco(20),
                    child: Text(usuario.rolTexto,
                        style: const TextStyle(color: C.light, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const _Seccion('Tu cuenta'),
        _Atajo(
          icono: Icons.manage_accounts_outlined,
          titulo: 'Editar perfil',
          detalle: 'Foto, datos personales y ubicación',
          onTap: () => abrir(const EditarPerfilScreen()),
        ),
        _Atajo(
          icono: Icons.location_on_outlined,
          titulo: 'Zona de trabajo',
          detalle: usuario.ubicacionTexto ?? 'Elige dónde trabajas',
          onTap: () => editarUbicacion(context),
        ),
        const SizedBox(height: 8),
        const _Seccion('Tu trabajo'),
        _Atajo(
          icono: Icons.handyman,
          titulo: 'Mis servicios',
          detalle: 'Lo que ofreces y tu disponibilidad',
          onTap: () => abrir(const MisServiciosScreen()),
        ),
        _Atajo(
          icono: Icons.assignment_outlined,
          titulo: 'Solicitudes recibidas',
          detalle: 'Acepta, completa y califica a tus clientes',
          onTap: () => abrir(const SolicitudesScreen(conAppBar: true)),
        ),
        _Atajo(
          icono: Icons.calendar_month,
          titulo: 'Mi agenda',
          detalle: 'Tu calendario de citas y trabajos',
          onTap: () => shell.ir(1),
        ),
        _Atajo(
          icono: Icons.add_a_photo_outlined,
          titulo: 'Publicar un trabajo',
          detalle: 'Sube fotos de lo que has hecho',
          onTap: () => abrir(const CrearPublicacionScreen()),
        ),
        _Atajo(
          icono: Icons.auto_awesome,
          titulo: 'Asistente IA',
          detalle: 'Cotizaciones, mensajes a clientes y descripciones',
          onTap: () => abrir(const AsistenteScreen()),
        ),
        const SizedBox(height: 18),
        OutlineButtonX(
          text: 'Cerrar sesión',
          icon: Icons.logout,
          onTap: () => context.read<AuthProvider>().cerrarSesion(),
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  final String texto;
  const _Seccion(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(texto.toUpperCase(),
            style: const TextStyle(
                color: C.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
      );
}

class _Atajo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;
  const _Atajo({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDeco(),
          child: Row(
            children: [
              Icon(icono, color: C.light),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(detalle, style: const TextStyle(color: C.muted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: C.muted),
            ],
          ),
        ),
      ),
    );
  }
}
