import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/core/widgets/rating.dart';
import 'package:manocerca/screens/perfil_trabajador/perfil_trabajador_screen.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/favorito_service.dart';
import 'package:provider/provider.dart';

/// Profesionales que el cliente guardó con el corazón.
class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  List<Favorito>? _favoritos;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (_error != null) setState(() => _error = null);
    try {
      final lista = await FavoritoService(context.read<ApiClient>()).listar();
      if (mounted) setState(() => _favoritos = lista);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.mensaje : 'No se pudieron cargar.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _favoritos;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis favoritos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: _error != null
            ? Center(child: EstadoError(mensaje: _error!, onReintentar: _cargar))
            : lista == null
                ? const Center(child: CircularProgressIndicator())
                : lista.isEmpty
                    ? const Center(
                        child: EstadoVacio(
                          icono: Icons.favorite_border,
                          titulo: 'Aún no guardas favoritos',
                          detalle: 'Toca el corazón en el perfil de un profesional.',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: lista.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final f = lista[i];
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PerfilTrabajadorScreen(idUsuario: f.idUsuario),
                                  ),
                                );
                                if (mounted) _cargar();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: cardDeco(),
                                child: Row(
                                  children: [
                                    Avatar(
                                        name: f.nombre,
                                        foto: urlFoto(context, f.foto),
                                        size: 52),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(f.nombre,
                                              style: const TextStyle(
                                                  fontSize: 15, fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 4),
                                          Text(
                                            f.disponible ? 'Disponible' : 'No disponible',
                                            style: TextStyle(
                                                color: f.disponible ? C.green : C.star,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    RatingChip(rating: f.calificacion, claro: false),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
