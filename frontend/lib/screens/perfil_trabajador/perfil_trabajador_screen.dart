import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manocerca/core/models/mi_servicio.dart';
import 'package:manocerca/core/models/pro.dart';
import 'package:manocerca/core/models/publicacion.dart';
import 'package:manocerca/core/models/resena.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/chat/chat_screen.dart';
import 'package:manocerca/screens/editar_perfil/editar_perfil_screen.dart';
import 'package:manocerca/screens/perfil_trabajador/widgets/cabecera_perfil.dart';
import 'package:manocerca/screens/perfil_trabajador/widgets/tab_precios.dart';
import 'package:manocerca/screens/perfil_trabajador/widgets/tab_resenas.dart';
import 'package:manocerca/screens/perfil_trabajador/widgets/tab_trabajos.dart';
import 'package:manocerca/screens/publicaciones/crear_publicacion_screen.dart';
import 'package:manocerca/screens/publicaciones/publicacion_detalle_screen.dart';
import 'package:manocerca/screens/request/request_screen.dart';
import 'package:manocerca/screens/reviews/reviews_screen.dart';
import 'package:manocerca/screens/servicios/mis_servicios_screen.dart';
import 'package:manocerca/screens/ubicacion/ubicacion_sheet.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/favorito_service.dart';
import 'package:manocerca/services/publicacion_service.dart';
import 'package:manocerca/services/resena_service.dart';
import 'package:manocerca/services/trabajador_service.dart';
import 'package:provider/provider.dart';

/// Pestaña "Perfil" del trabajador: su propio perfil, con "+" para publicar.
class MiPerfilTrabajadorScreen extends StatelessWidget {
  const MiPerfilTrabajadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = context.select<AuthProvider, int?>((a) => a.usuario?.id);
    if (id == null) return const SizedBox.shrink();
    return PerfilTrabajadorScreen(idUsuario: id, esPropio: true, enPestana: true);
  }
}

/// Perfil de un trabajador (diseño Figma "Perfil trabajos / precios / reseñas").
/// Lo ve el cliente al elegir un profesional y el propio trabajador en su pestaña.
class PerfilTrabajadorScreen extends StatefulWidget {
  final int idUsuario;

  /// Datos que ya se tenían de la lista (se muestran mientras carga).
  final Pro? pro;
  final bool esPropio;

  /// true cuando vive dentro de la barra inferior (sin botón de regresar).
  final bool enPestana;

  const PerfilTrabajadorScreen({
    super.key,
    required this.idUsuario,
    this.pro,
    this.esPropio = false,
    this.enPestana = false,
  });

  @override
  State<PerfilTrabajadorScreen> createState() => _PerfilTrabajadorScreenState();
}

class _PerfilTrabajadorScreenState extends State<PerfilTrabajadorScreen> {
  /// Con el número de trabajos y reseñas cuando ya se cargaron.
  List<String> get _titulos => [
        _publicaciones == null || _publicaciones!.isEmpty
            ? 'Trabajos'
            : 'Trabajos (${_publicaciones!.length})',
        'Rango de precios',
        _resenas == null || _resenas!.isEmpty ? 'Reseñas' : 'Reseñas (${_resenas!.length})',
      ];

  int _tab = 0;

  PerfilTrabajador? _perfil;
  String? _errorPerfil;
  List<Publicacion>? _publicaciones;
  String? _errorPublicaciones;
  List<Resena>? _resenas;
  String? _errorResenas;
  bool? _favorito;

  ApiClient get _api => context.read<ApiClient>();

  bool get _soyCliente {
    final u = context.read<AuthProvider>().usuario;
    return u != null && !u.esTrabajador;
  }

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    await Future.wait([
      _cargarPerfil(),
      _cargarPublicaciones(),
      _cargarResenas(),
      if (!widget.esPropio && _soyCliente) _cargarFavorito(),
    ]);
  }

  String _mensaje(Object e, String porDefecto) => e is ApiException ? e.mensaje : porDefecto;

  Future<void> _cargarPerfil() async {
    if (_errorPerfil != null) setState(() => _errorPerfil = null);
    try {
      final perfil = await TrabajadorService(_api).perfil(widget.idUsuario);
      if (mounted) setState(() => _perfil = perfil);
    } catch (e) {
      if (mounted) setState(() => _errorPerfil = _mensaje(e, 'No se pudo cargar el perfil.'));
    }
  }

  Future<void> _cargarPublicaciones() async {
    if (_errorPublicaciones != null) setState(() => _errorPublicaciones = null);
    try {
      final lista = await PublicacionService(_api).listar(idUsuario: widget.idUsuario);
      if (mounted) setState(() => _publicaciones = lista);
    } catch (e) {
      if (mounted) {
        setState(() => _errorPublicaciones = _mensaje(e, 'No se pudieron cargar los trabajos.'));
      }
    }
  }

  Future<void> _cargarResenas() async {
    if (_errorResenas != null) setState(() => _errorResenas = null);
    try {
      final lista = await ResenaService(_api).deUsuario(widget.idUsuario);
      if (mounted) setState(() => _resenas = lista);
    } catch (e) {
      if (mounted) {
        setState(() => _errorResenas = _mensaje(e, 'No se pudieron cargar las reseñas.'));
      }
    }
  }

  Future<void> _cargarFavorito() async {
    try {
      final favs = await FavoritoService(_api).listar();
      if (mounted) {
        setState(() => _favorito = favs.any((f) => f.idUsuario == widget.idUsuario));
      }
    } catch (_) {
      if (mounted) setState(() => _favorito = false);
    }
  }

  Future<void> _alternarFavorito() async {
    final antes = _favorito ?? false;
    setState(() => _favorito = !antes);
    try {
      final s = FavoritoService(_api);
      antes ? await s.quitar(widget.idUsuario) : await s.agregar(widget.idUsuario);
      if (mounted) mostrarAviso(context, antes ? 'Quitado de favoritos' : 'Guardado en favoritos');
    } catch (e) {
      if (!mounted) return;
      setState(() => _favorito = antes);
      mostrarAviso(context, _mensaje(e, 'No se pudo actualizar favoritos.'));
    }
  }

  String get _nombre {
    if (_perfil?.nombreCompleto.isNotEmpty == true) return _perfil!.nombreCompleto;
    if (widget.pro != null) return widget.pro!.name;
    // En su propio perfil, el nombre de la sesión mientras carga.
    if (widget.esPropio) return context.read<AuthProvider>().usuario?.nombreCompleto ?? '';
    return '';
  }

  double? get _calificacion => _perfil?.calificacion ?? widget.pro?.rating;

  /// La portada es la foto del trabajo más reciente.
  String? get _portada {
    for (final p in _publicaciones ?? const <Publicacion>[]) {
      if (p.portada != null) return p.portada;
    }
    return null;
  }

  void _compartir() {
    final oficios = _perfil?.oficios.join(', ') ?? widget.pro?.categoria ?? 'oficios';
    final cal = _calificacion == null ? '' : ' · ⭐ ${_calificacion!.toStringAsFixed(1)}';
    Clipboard.setData(ClipboardData(text: 'Conoce a $_nombre en Hogarix: $oficios$cal'));
    mostrarAviso(context, 'Perfil copiado para compartir');
  }

  Future<void> _abrir(Widget pantalla, {Future<void> Function()? alVolver}) async {
    final cambio = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => pantalla),
    );
    if (!mounted) return;
    if (alVolver != null && (cambio ?? true)) await alVolver();
  }

  Future<void> _publicar() => _abrir(
        const CrearPublicacionScreen(),
        alVolver: () async {
          setState(() => _tab = 0);
          await _cargarPublicaciones();
        },
      );

  Widget _filaInfo(IconData icono, String texto, {Color? color}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 16, color: color ?? C.light),
            const SizedBox(width: 8),
            Expanded(
              child: Text(texto,
                  style: TextStyle(color: color ?? Colors.white, fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _bloqueInfo() {
    final p = _perfil;
    if (p == null) {
      if (_errorPerfil != null) {
        return EstadoError(mensaje: _errorPerfil!, onReintentar: _cargarPerfil);
      }
      return const Padding(
        padding: EdgeInsets.all(20),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    final bio = (p.biografia ?? '').trim();
    return Container(
      width: double.infinity,
      color: C.navy,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.edad != null) _filaInfo(Icons.cake_outlined, 'Edad: ${p.edad} años'),
          if ((p.sexo ?? '').isNotEmpty) _filaInfo(Icons.person_outline, 'Sexo: ${p.sexo}'),
          if (p.oficios.isNotEmpty) _filaInfo(Icons.handyman_outlined, p.oficios.join(' · ')),
          if (p.ubicacion != null)
            _filaInfo(Icons.location_on_outlined, p.ubicacion!)
          else if (widget.esPropio)
            InkWell(
              onTap: () async {
                if (await editarUbicacion(context)) _cargarPerfil();
              },
              child: _filaInfo(Icons.add_location_alt_outlined, 'Agrega tu zona de trabajo',
                  color: C.light),
            ),
          if (p.fechaRegistro != null)
            _filaInfo(Icons.verified_outlined, 'En Hogarix desde ${p.fechaRegistro!.year}'),
          _filaInfo(
            Icons.circle,
            p.disponible ? 'Disponible para trabajar' : 'No disponible por ahora',
            color: p.disponible ? C.green : C.star,
          ),
          const SizedBox(height: 8),
          if (bio.isNotEmpty)
            Text(bio, style: const TextStyle(color: Color(0xFFD7E0F2), fontSize: 13, height: 1.45))
          else if (widget.esPropio)
            InkWell(
              onTap: _editarPerfil,
              child: const Text(
                'Agrega una descripción: tu experiencia, en qué te especializas y tu zona de trabajo.',
                style: TextStyle(color: C.muted, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editarPerfil() async {
    final p = _perfil;
    if (p == null) return;
    await _abrir(EditarPerfilScreen(perfil: p), alVolver: _cargarPerfil);
  }

  Widget _contenidoTab() {
    switch (_tab) {
      case 0:
        return TabTrabajos(
          publicaciones: _publicaciones,
          error: _errorPublicaciones,
          esPropio: widget.esPropio,
          onReintentar: _cargarPublicaciones,
          onPublicar: _publicar,
          onAbrir: (p) => _abrir(
            PublicacionDetalleScreen(publicacion: p, esPropia: widget.esPropio),
            alVolver: _cargarPublicaciones,
          ),
        );
      case 1:
        final p = _perfil;
        if (p == null) {
          return _errorPerfil != null
              ? EstadoError(mensaje: _errorPerfil!, onReintentar: _cargarPerfil)
              : const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
        }
        return TabPrecios(
          perfil: p,
          esPropio: widget.esPropio,
          onAdministrar: () => _abrir(const MisServiciosScreen(), alVolver: _cargarPerfil),
        );
      default:
        return TabResenas(
          resenas: _resenas,
          error: _errorResenas,
          onReintentar: _cargarResenas,
          idTrabajador: widget.idUsuario,
          onVerTodas: () => _abrir(
            ReviewsScreen(idUsuario: widget.idUsuario, nombre: _nombre),
          ),
        );
    }
  }

  Widget? _botonesContacto() {
    if (widget.esPropio) return null;
    final puedeSolicitar = _soyCliente && _perfil != null && _perfil!.servicios.isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: C.bg2,
          border: Border(top: BorderSide(color: C.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlineButtonX(
                text: 'Mensaje',
                icon: Icons.chat_bubble_outline,
                onTap: () => _abrir(ChatScreen(
                  idOtroUsuario: widget.idUsuario,
                  nombre: _nombre,
                  foto: _perfil?.fotoPerfil ?? widget.pro?.fotoPerfil,
                )),
              ),
            ),
            if (_soyCliente) ...[
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  text: 'Solicitar',
                  icon: Icons.event_available_outlined,
                  onTap: puedeSolicitar
                      ? () => _abrir(RequestScreen(
                            perfil: _perfil!,
                            idCategoriaInicial: widget.pro?.idCategoria,
                          ))
                      : () => mostrarAviso(context, 'Este profesional aún no registra servicios.'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contenido = RefreshIndicator(
      onRefresh: _cargarTodo,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CabeceraPerfil(
              nombre: _nombre.isEmpty ? 'Cargando…' : _nombre,
              foto: _perfil?.fotoPerfil ?? widget.pro?.fotoPerfil,
              portada: _portada,
              calificacion: _calificacion,
              esPropio: widget.esPropio,
              mostrarAtras: !widget.enPestana,
              favorito: _favorito,
              onFavorito: _favorito == null ? null : _alternarFavorito,
              onCompartir: _compartir,
              onEditar: _editarPerfil,
            ),
            const SizedBox(height: 14),
            _bloqueInfo(),
            PestanasPerfil(
              titulos: _titulos,
              actual: _tab,
              onCambiar: (i) => setState(() => _tab = i),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              child: _contenidoTab(),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: widget.enPestana ? contenido : SafeArea(bottom: false, child: contenido),
      floatingActionButton: widget.esPropio && _tab == 0
          ? FloatingActionButton(
              tooltip: 'Publicar trabajo',
              backgroundColor: C.primary,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              onPressed: _publicar,
              child: const Icon(Icons.add, size: 30),
            )
          : null,
      bottomNavigationBar: _botonesContacto(),
    );
  }
}
