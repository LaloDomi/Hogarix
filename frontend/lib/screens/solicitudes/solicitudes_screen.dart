import 'package:flutter/material.dart';
import 'package:manocerca/core/models/solicitud.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/chat/chat_screen.dart';
import 'package:manocerca/screens/perfil_trabajador/perfil_trabajador_screen.dart';
import 'package:manocerca/screens/visitas/agendar_visita_screen.dart';
import 'package:manocerca/screens/solicitudes/acciones_solicitud.dart';
import 'package:manocerca/screens/solicitudes/widgets/solicitud_card.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/solicitud_service.dart';
import 'package:provider/provider.dart';

/// Solicitudes del usuario: el cliente ve las que envió y el trabajador las
/// que recibió. Desde aquí se aceptan, completan, cancelan y califican.
class SolicitudesScreen extends StatefulWidget {
  /// Se usa como pestaña (sin botón de regresar) o como pantalla aparte.
  final bool conAppBar;
  const SolicitudesScreen({super.key, this.conAppBar = false});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  static const _filtros = <(String, bool Function(Solicitud))>[
    ('Todas', _todas),
    ('Activas', _activas),
    ('Por calificar', _porCalificar),
    ('Completadas', _completadas),
    ('Canceladas', _canceladas),
  ];

  static bool _todas(Solicitud s) => true;
  static bool _activas(Solicitud s) =>
      s.estado == EstadoSolicitud.pendiente || s.estado == EstadoSolicitud.aceptado;
  static bool _porCalificar(Solicitud s) => s.porCalificar;
  static bool _completadas(Solicitud s) => s.completada;
  static bool _canceladas(Solicitud s) =>
      s.estado == EstadoSolicitud.cancelado || s.estado == EstadoSolicitud.rechazado;

  int _filtro = 0;
  List<Solicitud>? _solicitudes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (_error != null) setState(() => _error = null);
    try {
      final lista = await SolicitudService(context.read<ApiClient>()).listar();
      if (mounted) setState(() => _solicitudes = lista);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = e is ApiException ? e.mensaje : 'No se pudieron cargar tus solicitudes.');
      }
    }
  }

  Future<void> _cambiar(Solicitud s, String estado, int idYo) async {
    if (await cambiarEstadoSolicitud(context, s, estado, idYo)) await _cargar();
  }

  Future<void> _calificar(Solicitud s, int idYo) async {
    if (await abrirCalificacion(context, s, idYo)) await _cargar();
  }

  Future<void> _agendar(Solicitud s) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AgendarVisitaScreen(solicitud: s)),
    );
    if (ok == true && mounted) await _cargar();
  }

  Widget _contenido(int idYo, bool soyTrabajador) {
    if (_error != null) {
      return ListView(children: [EstadoError(mensaje: _error!, onReintentar: _cargar)]);
    }
    final todas = _solicitudes;
    if (todas == null) return const Center(child: CircularProgressIndicator());

    final porCalificar = todas.where((s) => s.porCalificar).length;
    final visibles = todas.where(_filtros[_filtro].$2).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (porCalificar > 0 && _filtro != 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: const Color(0x33FFB800),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _filtro = 2),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: C.star, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          porCalificar == 1
                              ? 'Tienes 1 trabajo por calificar'
                              : 'Tienes $porCalificar trabajos por calificar',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: C.star),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (visibles.isEmpty)
          EstadoVacio(
            icono: Icons.assignment_outlined,
            titulo: todas.isEmpty ? 'Aún no tienes solicitudes' : 'Nada por aquí',
            detalle: todas.isEmpty
                ? (soyTrabajador
                    ? 'Cuando un cliente te solicite un trabajo aparecerá aquí.'
                    : 'Busca un profesional y solicítale un servicio.')
                : 'No hay solicitudes con este filtro.',
          ),
        for (final s in visibles)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SolicitudCard(
              solicitud: s,
              idYo: idYo,
              soyTrabajador: soyTrabajador,
              onCambiarEstado: (estado) => _cambiar(s, estado, idYo),
              onCalificar: () => _calificar(s, idYo),
              onAgendar: () => _agendar(s),
              onMensaje: () {
                final otro = s.contraparte(idYo);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChatScreen(idOtroUsuario: otro.id, nombre: otro.nombre, foto: otro.foto),
                  ),
                );
              },
              onAbrirPerfil: soyTrabajador
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PerfilTrabajadorScreen(idUsuario: s.idTrabajador),
                        ),
                      ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    if (usuario == null) return const SizedBox.shrink();
    final titulo = usuario.esTrabajador ? 'Solicitudes recibidas' : 'Mis solicitudes';

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.conAppBar)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(titulo,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (int i = 0; i < _filtros.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_filtros[i].$1),
                    selected: _filtro == i,
                    onSelected: (_) => setState(() => _filtro = i),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargar,
            child: _contenido(usuario.id, usuario.esTrabajador),
          ),
        ),
      ],
    );

    if (!widget.conAppBar) return cuerpo;
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(child: cuerpo),
    );
  }
}
