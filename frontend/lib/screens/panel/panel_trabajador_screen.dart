import 'package:flutter/material.dart';
import 'package:manocerca/core/models/mi_servicio.dart';
import 'package:manocerca/core/models/solicitud.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/home/widgets/encabezado_inicio.dart';
import 'package:manocerca/screens/main_shell/shell_controller.dart';
import 'package:manocerca/screens/ubicacion/aviso_ubicacion.dart';
import 'package:manocerca/screens/visitas/agendar_visita_screen.dart';
import 'package:manocerca/screens/publicaciones/crear_publicacion_screen.dart';
import 'package:manocerca/screens/servicios/mis_servicios_screen.dart';
import 'package:manocerca/screens/solicitudes/acciones_solicitud.dart';
import 'package:manocerca/screens/solicitudes/solicitudes_screen.dart';
import 'package:manocerca/screens/solicitudes/widgets/solicitud_card.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/solicitud_service.dart';
import 'package:manocerca/services/trabajador_service.dart';
import 'package:provider/provider.dart';

/// Inicio del trabajador: su disponibilidad, sus números y las solicitudes
/// nuevas para aceptar o rechazar sin buscar en otro lado.
class PanelTrabajadorScreen extends StatefulWidget {
  const PanelTrabajadorScreen({super.key});

  @override
  State<PanelTrabajadorScreen> createState() => _PanelTrabajadorScreenState();
}

class _PanelTrabajadorScreenState extends State<PanelTrabajadorScreen> {
  PerfilTrabajador? _perfil;
  List<Solicitud>? _solicitudes;
  String? _error;
  bool _cambiandoDisponible = false;

  int get _idYo => context.read<AuthProvider>().usuario!.id;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    await Future.wait([_cargarPerfil(), _cargarSolicitudes()]);
  }

  Future<void> _cargarPerfil() async {
    if (_error != null) setState(() => _error = null);
    try {
      final perfil = await TrabajadorService(context.read<ApiClient>()).perfil(_idYo);
      if (mounted) setState(() => _perfil = perfil);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.mensaje : 'No se pudo cargar tu panel.');
      }
    }
  }

  /// Si falla, el panel sigue funcionando sin la lista de solicitudes.
  Future<void> _cargarSolicitudes() async {
    List<Solicitud> lista;
    try {
      lista = await SolicitudService(context.read<ApiClient>()).listar();
    } catch (_) {
      lista = const [];
    }
    if (mounted) setState(() => _solicitudes = lista);
  }

  Future<void> _cambiarDisponible(bool valor) async {
    final p = _perfil;
    if (p == null || _cambiandoDisponible) return;
    setState(() {
      _cambiandoDisponible = true;
      _perfil = p.copyWith(disponible: valor);
    });
    try {
      await TrabajadorService(context.read<ApiClient>()).actualizarDisponibilidad(valor);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _perfil = p);
        mostrarAviso(context, e.mensaje);
      }
    } finally {
      if (mounted) setState(() => _cambiandoDisponible = false);
    }
  }

  Future<void> _ir(Widget pantalla) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
    if (mounted) _cargar();
  }

  Widget _dato(IconData icono, String valor, String etiqueta, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: cardDeco(14),
          child: Column(
            children: [
              Icon(icono, color: color, size: 22),
              const SizedBox(height: 6),
              Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(etiqueta,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: C.muted, fontSize: 11)),
            ],
          ),
        ),
      );

  Widget _atajo(IconData icono, String texto, VoidCallback onTap) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 86,
            decoration: cardDeco(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, color: C.light, size: 26),
                const SizedBox(height: 6),
                Text(texto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    if (usuario == null) return const SizedBox.shrink();
    final shell = context.read<ShellController>();
    final perfil = _perfil;
    final solicitudes = _solicitudes ?? const <Solicitud>[];
    final pendientes =
        solicitudes.where((s) => s.estado == EstadoSolicitud.pendiente).toList();
    final completadas = solicitudes.where((s) => s.completada).length;
    final porCalificar = solicitudes.where((s) => s.porCalificar).toList();

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const EncabezadoInicio(),
          const SizedBox(height: 10),
          Text('Hola, ${usuario.nombre}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Este es tu panel de trabajo',
              style: TextStyle(color: C.muted, fontSize: 15)),
          if (!usuario.tieneUbicacion) ...[
            const SizedBox(height: 14),
            const AvisoUbicacion(),
          ],
          const SizedBox(height: 18),
          if (_error != null && perfil == null)
            EstadoError(mensaje: _error!, onReintentar: _cargar)
          else if (perfil == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else ...[
            // Disponibilidad
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: perfil.disponible
                      ? const [Color(0xFF14532D), Color(0xFF14284B)]
                      : const [Color(0xFF3F2D0B), Color(0xFF14284B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Icon(perfil.disponible ? Icons.work_outline : Icons.work_off_outlined,
                      color: perfil.disponible ? C.green : C.star),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(perfil.disponible ? 'Estás disponible' : 'No estás disponible',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(
                          perfil.disponible
                              ? 'Apareces primero en las búsquedas'
                              : 'Los clientes verán que no tomas trabajos',
                          style: const TextStyle(color: C.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: perfil.disponible,
                    onChanged: _cambiandoDisponible ? null : _cambiarDisponible,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _dato(Icons.star_rounded, perfil.calificacion?.toStringAsFixed(1) ?? '–',
                    'Calificación', C.star),
                const SizedBox(width: 10),
                _dato(Icons.check_circle_outline, '$completadas', 'Completados', C.green),
                const SizedBox(width: 10),
                _dato(Icons.schedule, '${pendientes.length}', 'Pendientes', C.light),
              ],
            ),
          ],
          if (porCalificar.isNotEmpty) ...[
            const SizedBox(height: 12),
            Material(
              color: const Color(0x33FFB800),
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.star_rounded, color: C.star, size: 30),
                title: Text(
                  porCalificar.length == 1
                      ? 'Califica a tu último cliente'
                      : 'Tienes ${porCalificar.length} clientes por calificar',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                trailing: const Icon(Icons.chevron_right, color: C.star),
                onTap: () async {
                  if (await abrirCalificacion(context, porCalificar.first, _idYo)) _cargar();
                },
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text('Solicitudes nuevas',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () => _ir(const SolicitudesScreen(conAppBar: true)),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          if (_solicitudes != null && pendientes.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDeco(14),
              child: const Row(
                children: [
                  Icon(Icons.inbox_outlined, color: C.muted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('No tienes solicitudes pendientes por ahora.',
                        style: TextStyle(color: C.muted)),
                  ),
                ],
              ),
            ),
          for (final s in pendientes.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SolicitudCard(
                solicitud: s,
                idYo: _idYo,
                soyTrabajador: true,
                onCambiarEstado: (estado) async {
                  if (await cambiarEstadoSolicitud(context, s, estado, _idYo)) _cargar();
                },
                onCalificar: () async {
                  if (await abrirCalificacion(context, s, _idYo)) _cargar();
                },
                onAgendar: () => _ir(AgendarVisitaScreen(solicitud: s)),
              ),
            ),
          const SizedBox(height: 14),
          const Text('Accesos rápidos',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              _atajo(Icons.add_a_photo_outlined, 'Publicar\ntrabajo',
                  () => _ir(const CrearPublicacionScreen())),
              const SizedBox(width: 10),
              _atajo(Icons.handyman_outlined, 'Servicios\ny precios',
                  () => _ir(const MisServiciosScreen())),
              const SizedBox(width: 10),
              _atajo(Icons.calendar_month_outlined, 'Ver\ncalendario', () => shell.ir(1)),
            ],
          ),
        ],
      ),
    );
  }
}
