import 'package:flutter/material.dart';
import 'package:manocerca/core/models/resena.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/screens/perfil_trabajador/widgets/tab_resenas.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/resena_service.dart';
import 'package:provider/provider.dart';

/// Todas las reseñas que ha recibido un usuario (trabajador o cliente).
class ReviewsScreen extends StatefulWidget {
  final int idUsuario;
  final String nombre;
  const ReviewsScreen({super.key, required this.idUsuario, required this.nombre});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Resena>? _resenas;
  String? _error;
  int _filtro = 0; // 0 = todas, 1..5 = solo esas estrellas

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (_error != null) setState(() => _error = null);
    try {
      final lista = await ResenaService(context.read<ApiClient>()).deUsuario(widget.idUsuario);
      if (mounted) setState(() => _resenas = lista);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.mensaje : 'No se pudieron cargar.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todas = _resenas;
    final visibles = (todas ?? const <Resena>[])
        .where((r) => _filtro == 0 || r.calificacion == _filtro)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Reseñas de ${widget.nombre.split(' ').first}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: _error != null
            ? Center(child: EstadoError(mensaje: _error!, onReintentar: _cargar))
            : todas == null
                ? const Center(child: CircularProgressIndicator())
                : todas.isEmpty
                    ? const Center(
                        child: EstadoVacio(
                          icono: Icons.star_outline_rounded,
                          titulo: 'Sin reseñas aún',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            ResumenEstrellas(resumen: ResumenResenas.de(todas)),
                            const SizedBox(height: 14),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final f in [0, 5, 4, 3, 2, 1])
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(f == 0 ? 'Todas' : '$f ★'),
                                        selected: _filtro == f,
                                        onSelected: (_) => setState(() => _filtro = f),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (visibles.isEmpty)
                              const EstadoVacio(
                                icono: Icons.filter_alt_off_outlined,
                                titulo: 'No hay reseñas con ese filtro',
                              ),
                            for (final r in visibles)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TarjetaResena(resena: r),
                              ),
                          ],
                        ),
                      ),
      ),
    );
  }
}
