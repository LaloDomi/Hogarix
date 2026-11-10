import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/categoria_icono.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/providers/categorias_provider.dart';
import 'package:manocerca/screens/asistente/asistente_screen.dart';
import 'package:manocerca/screens/home/widgets/encabezado_inicio.dart';
import 'package:manocerca/screens/home/widgets/trabajos_recientes.dart';
import 'package:manocerca/screens/main_shell/shell_controller.dart';
import 'package:manocerca/screens/pro_list/pro_list_screen.dart';
import 'package:provider/provider.dart';

/// Inicio del cliente: buscador, categorías y trabajos recientes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoriasProvider>().cargarSiHaceFalta();
    });
  }

  Widget _categorias(CategoriasProvider cats) {
    if (cats.items.isEmpty) {
      if (cats.cargando) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (cats.error != null) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(cats.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: C.muted, fontSize: 14)),
              const SizedBox(height: 8),
              TextButton(onPressed: cats.recargar, child: const Text('Reintentar')),
            ],
          ),
        );
      }
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Aún no hay categorías disponibles.',
              style: TextStyle(color: C.muted, fontSize: 14)),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: [
        for (final c in cats.items)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProListScreen(categoria: c)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: cardDeco(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconoDeCategoria(c.nombre), color: C.light, size: 30),
                  const SizedBox(height: 8),
                  Text(c.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final nombre = usuario?.nombre ?? '';
    final cats = context.watch<CategoriasProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EncabezadoInicio(mostrarMensajes: true),
          const SizedBox(height: 14),
          Text('Hola, $nombre',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('¿Qué servicio necesitas hoy?',
              style: TextStyle(color: C.muted, fontSize: 15)),
          const SizedBox(height: 16),
          // Abre la pestaña Buscar, donde se filtra mientras se escribe.
          TextField(
            readOnly: true,
            onTap: () {
              final shell = context.read<ShellController>();
              shell.busquedaPendiente = '';
              shell.ir(1);
            },
            decoration: inputDeco('Buscar un oficio o profesional...',
                prefix: const Icon(Icons.search, color: C.muted)),
          ),
          const SizedBox(height: 14),
          const _BannerAsistente(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Categorías',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => context.read<ShellController>().ir(1),
                child: const Text('Ver todas',
                    style: TextStyle(color: C.primary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _categorias(cats),
          const TrabajosRecientes(),
        ],
      ),
    );
  }
}

/// Atajo al asistente con IA: para quien no sabe qué oficio necesita.
class _BannerAsistente extends StatelessWidget {
  const _BannerAsistente();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AsistenteScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [C.primary.withValues(alpha: 0.30), C.card],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome, color: C.light, size: 30),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿No sabes a quién llamar?',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Cuéntale tu problema al asistente IA y te dice qué oficio necesitas.',
                      style: TextStyle(color: C.muted, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: C.muted),
          ],
        ),
      ),
    );
  }
}
