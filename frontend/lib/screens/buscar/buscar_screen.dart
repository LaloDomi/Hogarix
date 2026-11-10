import 'package:flutter/material.dart';
import 'package:manocerca/core/models/categoria.dart';
import 'package:manocerca/core/models/filtros_busqueda.dart';
import 'package:manocerca/core/models/pro.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/core/widgets/tarjeta_pro.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/providers/categorias_provider.dart';
import 'package:manocerca/screens/buscar/filtros_sheet.dart';
import 'package:manocerca/screens/main_shell/shell_controller.dart';
import 'package:manocerca/screens/perfil_trabajador/perfil_trabajador_screen.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/servicio_service.dart';
import 'package:provider/provider.dart';

/// Pestaña "Buscar" del cliente: búsqueda por texto que filtra mientras se
/// escribe, categorías y filtros (calificación, precio, forma de cobro,
/// disponibilidad y orden).
class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  final _texto = TextEditingController();
  final _foco = FocusNode();
  FiltrosBusqueda _filtros = const FiltrosBusqueda();

  /// Resultados del backend por categoría (se piden una sola vez).
  final Map<int, List<Pro>> _porCategoria = {};
  final Set<int> _cargando = {};
  String? _error;

  late final ShellController _shell;

  @override
  void initState() {
    super.initState();
    _shell = context.read<ShellController>();
    _shell.addListener(_revisarBusquedaPendiente);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _revisarBusquedaPendiente();
      await context.read<CategoriasProvider>().cargarSiHaceFalta();
      if (mounted) _cargarFaltantes();
    });
  }

  @override
  void dispose() {
    _shell.removeListener(_revisarBusquedaPendiente);
    _texto.dispose();
    _foco.dispose();
    super.dispose();
  }

  /// El buscador del Inicio deja aquí lo que el cliente escribió.
  void _revisarBusquedaPendiente() {
    final pendiente = _shell.busquedaPendiente;
    if (pendiente == null || !mounted) return;
    _shell.busquedaPendiente = null;
    _texto.text = pendiente;
    setState(() => _filtros = _filtros.copyWith(texto: pendiente));
    if (pendiente.isEmpty) _foco.requestFocus();
  }

  List<Categoria> get _categorias => context.read<CategoriasProvider>().items;

  /// Pide al backend las categorías que hagan falta para los filtros actuales.
  Future<void> _cargarFaltantes() async {
    final ids = _filtros.idCategoria != null
        ? [_filtros.idCategoria!]
        : [for (final c in _categorias) c.id];
    final faltan = ids
        .where((id) => !_porCategoria.containsKey(id) && !_cargando.contains(id))
        .toList();
    if (faltan.isEmpty) return;

    final service = ServicioService(context.read<ApiClient>());
    setState(() {
      _error = null;
      _cargando.addAll(faltan);
    });
    await Future.wait(faltan.map((id) async {
      try {
        final pros = await service.buscar(idCategoria: id);
        _porCategoria[id] = pros;
      } on ApiException catch (e) {
        _error = e.mensaje;
      } catch (_) {
        _error = 'No se pudieron cargar los profesionales.';
      } finally {
        _cargando.remove(id);
      }
    }));
    if (mounted) setState(() {});
  }

  void _cambiar(FiltrosBusqueda f) {
    setState(() => _filtros = f);
    _cargarFaltantes();
  }

  Future<void> _abrirFiltros(List<Pro> base) async {
    final precios = [for (final p in base) if (p.precioBase != null) p.precioBase!];
    final tope = precios.isEmpty
        ? 1000.0
        : (precios.reduce((a, b) => a > b ? a : b) / 100).ceil() * 100.0;
    final u = context.read<AuthProvider>().usuario;
    final elegidos = await mostrarFiltros(
      context,
      actuales: _filtros.copyWith(miEstado: () => u?.estadoMx, miMunicipio: () => u?.municipio),
      precioTope: tope,
    );
    if (elegidos != null) _cambiar(elegidos);
  }

  Widget _chip(String texto, bool activo, VoidCallback onTap, {IconData? icono}) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: activo ? C.primary : C.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: activo ? C.primary : C.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icono != null) ...[
                  Icon(icono, size: 15, color: activo ? Colors.white : C.star),
                  const SizedBox(width: 4),
                ],
                Text(texto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoriasProvider>();
    final usuario = context.watch<AuthProvider>().usuario;
    // Mi ubicación del perfil: ordena primero a los cercanos y habilita "En mi zona".
    final filtros = _filtros.copyWith(
      miEstado: () => usuario?.estadoMx,
      miMunicipio: () => usuario?.municipio,
    );
    final base = _filtros.idCategoria != null
        ? (_porCategoria[_filtros.idCategoria] ?? const <Pro>[])
        : [for (final l in _porCategoria.values) ...l];
    final resultados = filtros.aplicar(base);
    final cargando = _cargando.isNotEmpty || (cats.cargando && cats.items.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text('Buscar', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _texto,
                  focusNode: _foco,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _filtros = _filtros.copyWith(texto: v)),
                  decoration: inputDeco(
                    'Nombre, oficio o trabajo…',
                    prefix: const Icon(Icons.search, color: C.muted),
                  ).copyWith(
                    suffixIcon: _texto.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, color: C.muted, size: 20),
                            onPressed: () {
                              _texto.clear();
                              setState(() => _filtros = _filtros.copyWith(texto: ''));
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Badge(
                isLabelVisible: _filtros.activos > 0,
                label: Text('${_filtros.activos}'),
                child: Material(
                  color: _filtros.activos > 0 ? C.primary : C.card,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _abrirFiltros(base),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: C.border),
                      ),
                      child: const Icon(Icons.tune, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Categorías
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _chip('Todas', _filtros.idCategoria == null,
                  () => _cambiar(_filtros.copyWith(idCategoria: () => null))),
              for (final c in cats.items)
                _chip(c.nombre, _filtros.idCategoria == c.id,
                    () => _cambiar(_filtros.copyWith(idCategoria: () => c.id))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Filtros rápidos
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              if (usuario?.estadoMx != null)
                _chip('En mi zona', _filtros.soloMiZona,
                    () => _cambiar(_filtros.copyWith(soloMiZona: !_filtros.soloMiZona)),
                    icono: Icons.location_on),
              _chip('Disponibles', _filtros.soloDisponibles,
                  () => _cambiar(_filtros.copyWith(soloDisponibles: !_filtros.soloDisponibles)),
                  icono: Icons.bolt),
              _chip('4+', _filtros.calificacionMin >= 4,
                  () => _cambiar(_filtros.copyWith(
                      calificacionMin: _filtros.calificacionMin >= 4 ? 0 : 4)),
                  icono: Icons.star_rounded),
              _chip('Menor precio', _filtros.orden == OrdenBusqueda.menorPrecio,
                  () => _cambiar(_filtros.copyWith(
                      orden: _filtros.orden == OrdenBusqueda.menorPrecio
                          ? OrdenBusqueda.recomendados
                          : OrdenBusqueda.menorPrecio)),
                  icono: Icons.south),
              _chip('Mejor calificados', _filtros.orden == OrdenBusqueda.mejorCalificados,
                  () => _cambiar(_filtros.copyWith(
                      orden: _filtros.orden == OrdenBusqueda.mejorCalificados
                          ? OrdenBusqueda.recomendados
                          : OrdenBusqueda.mejorCalificados)),
                  icono: Icons.emoji_events_outlined),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Text(
                cargando && base.isEmpty
                    ? 'Buscando profesionales…'
                    : resultados.length == 1
                        ? '1 resultado'
                        : '${resultados.length} resultados',
                style: const TextStyle(color: C.muted, fontSize: 13),
              ),
              if (cargando) ...[
                const SizedBox(width: 8),
                const SizedBox(
                    width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
              const Spacer(),
              if (_filtros.activos > 0 || _filtros.texto.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _texto.clear();
                    _cambiar(FiltrosBusqueda(idCategoria: _filtros.idCategoria));
                  },
                  child: const Text('Quitar filtros',
                      style: TextStyle(color: C.primary, fontSize: 13)),
                ),
            ],
          ),
        ),
        Expanded(
          child: _error != null && base.isEmpty
              ? ListView(children: [
                  EstadoError(
                    mensaje: _error!,
                    onReintentar: () {
                      setState(() => _error = null);
                      _cargarFaltantes();
                    },
                  ),
                ])
              : resultados.isEmpty && !cargando
                  ? ListView(children: [
                      EstadoVacio(
                        icono: Icons.search_off,
                        titulo: 'Sin resultados',
                        detalle: base.isEmpty
                            ? 'Aún no hay profesionales registrados aquí.'
                            : 'Prueba con otra palabra o quita algunos filtros.',
                      ),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: resultados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final p = resultados[i];
                        return TarjetaPro(
                          pro: p,
                          mostrarCategoria: _filtros.idCategoria == null,
                          onTap: p.id == null
                              ? () {}
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PerfilTrabajadorScreen(idUsuario: p.id!, pro: p),
                                    ),
                                  ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
