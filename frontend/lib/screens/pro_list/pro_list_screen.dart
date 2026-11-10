import 'package:flutter/material.dart';
import 'package:manocerca/core/models/categoria.dart';
import 'package:manocerca/core/models/pro.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/texto.dart';
import 'package:manocerca/core/widgets/tarjeta_pro.dart';
import 'package:manocerca/screens/perfil_trabajador/perfil_trabajador_screen.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/servicio_service.dart';
import 'package:provider/provider.dart';

class ProListScreen extends StatefulWidget {
  final Categoria categoria;
  const ProListScreen({super.key, required this.categoria});

  @override
  State<ProListScreen> createState() => _ProListScreenState();
}

class _ProListScreenState extends State<ProListScreen> {
  // Etiqueta que ve el usuario -> valor que entiende el backend (null = todos).
  static const _filtros = <(String, String?)>[
    ('Todos', null),
    ('Por día', 'Día'),
    ('Destajo', 'Destajo'),
    ('Por trabajo', 'Por trabajo'),
    ('Por hora', 'Por hora'),
  ];

  int _filtro = 0;
  String _busqueda = '';

  List<Pro> _pros = const [];
  bool _cargando = true;
  String? _error;
  int _peticion = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final peticion = ++_peticion;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final pros = await ServicioService(context.read<ApiClient>()).buscar(
        idCategoria: widget.categoria.id,
        tipoPago: _filtros[_filtro].$2,
      );
      // Si el usuario cambió de filtro mientras tanto, esta respuesta ya no sirve.
      if (!mounted || peticion != _peticion) return;
      setState(() {
        _pros = pros;
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted || peticion != _peticion) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted || peticion != _peticion) return;
      setState(() {
        _error = 'No se pudo cargar la lista. Intenta de nuevo.';
        _cargando = false;
      });
    }
  }

  void _elegirFiltro(int i) {
    if (i == _filtro) return;
    setState(() => _filtro = i);
    _cargar();
  }

  /// Filtra al instante por nombre o descripción mientras se escribe.
  List<Pro> get _visibles {
    final q = normalizar(_busqueda);
    if (q.isEmpty) return _pros;
    return _pros
        .where((p) => normalizar('${p.name} ${p.descripcion ?? ''}').contains(q))
        .toList();
  }

  String get _resumen {
    if (_cargando) return 'Buscando profesionales...';
    final n = _visibles.length;
    return n == 1 ? '1 profesional' : '$n profesionales';
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: C.muted, fontSize: 14)),
            const SizedBox(height: 8),
            TextButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    final visibles = _visibles;
    if (visibles.isEmpty) {
      return const Center(
        child: Text(
          'Aún no hay profesionales con este filtro.',
          textAlign: TextAlign.center,
          style: TextStyle(color: C.muted, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      itemCount: visibles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = visibles[i];
        return TarjetaPro(
          pro: p,
          onTap: p.id == null
              ? () {}
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PerfilTrabajadorScreen(idUsuario: p.id!, pro: p),
                    ),
                  ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.categoria.nombre,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(_resumen, style: const TextStyle(color: C.muted, fontSize: 15)),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _busqueda = v),
              decoration: inputDeco('Buscar por nombre o especialidad…',
                  prefix: const Icon(Icons.search, color: C.muted)),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < _filtros.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _elegirFiltro(i),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: _filtro == i ? C.primary : C.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _filtro == i ? C.primary : C.border),
                          ),
                          child: Text(_filtros[i].$1,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: _contenido()),
          ],
        ),
      ),
    );
  }
}
