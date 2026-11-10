import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manocerca/core/models/conversacion.dart';
import 'package:manocerca/core/models/solicitud.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/providers/avisos_provider.dart';
import 'package:manocerca/screens/agenda/agenda_screen.dart';
import 'package:manocerca/screens/buscar/buscar_screen.dart';
import 'package:manocerca/screens/calificar/aviso_calificacion.dart';
import 'package:manocerca/screens/home/home_screen.dart';
import 'package:manocerca/screens/mas/mas_screen.dart';
import 'package:manocerca/screens/messages/messages_screen.dart';
import 'package:manocerca/screens/notificaciones/notificaciones_screen.dart';
import 'package:manocerca/screens/panel/panel_trabajador_screen.dart';
import 'package:manocerca/screens/perfil_cliente/perfil_cliente_screen.dart';
import 'package:manocerca/screens/perfil_trabajador/perfil_trabajador_screen.dart';
import 'package:manocerca/screens/solicitudes/solicitudes_screen.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/solicitud_service.dart';
import 'package:manocerca/screens/main_shell/shell_controller.dart';
import 'package:provider/provider.dart';

/// Una pestaña = la pantalla + su botón en la barra inferior.
class _Tab {
  final Widget Function() pagina;
  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;
  const _Tab(this.pagina, this.icono, this.iconoActivo, this.etiqueta);
}

/// Contenedor con la barra de navegación inferior. Clientes y trabajadores
/// ven pestañas y pantallas distintas.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  late final ShellController _shell;
  late final AvisosProvider _avisos;

  /// Cada cuánto se revisan las notificaciones con la app abierta.
  static const _cadaCuanto = Duration(seconds: 45);
  Timer? _revision;

  /// Solo se construyen las pestañas que ya se abrieron (carga más rápida).
  final Set<int> _abiertas = {0};

  // Mensajes del cliente: icono en el encabezado del Inicio.
  static final _tabsCliente = <_Tab>[
    _Tab(() => const HomeScreen(), Icons.home_outlined, Icons.home_filled, 'Inicio'),
    _Tab(() => const BuscarScreen(), Icons.search, Icons.search, 'Buscar'),
    _Tab(() => const AgendaScreen(), Icons.calendar_month_outlined, Icons.calendar_month,
        'Agenda'),
    _Tab(() => const SolicitudesScreen(), Icons.assignment_outlined,
        Icons.assignment, 'Solicitudes'),
    _Tab(() => const PerfilClienteScreen(), Icons.person_outline, Icons.person, 'Perfil'),
  ];

  static final _tabsTrabajador = <_Tab>[
    _Tab(() => const PanelTrabajadorScreen(), Icons.home_outlined, Icons.home_filled,
        'Inicio'),
    _Tab(() => const AgendaScreen(), Icons.calendar_month_outlined, Icons.calendar_month,
        'Calendario'),
    _Tab(() => const MessagesScreen(), Icons.chat_bubble_outline, Icons.chat_bubble,
        'Mensajes'),
    _Tab(() => const MiPerfilTrabajadorScreen(), Icons.person_outline, Icons.person,
        'Perfil'),
    _Tab(() => const MasScreen(), Icons.menu, Icons.menu, 'Más'),
  ];

  @override
  void initState() {
    super.initState();
    _shell = context.read<ShellController>()..reiniciar();
    _shell.addListener(_alCambiarPestana);
    _avisos = context.read<AvisosProvider>()..reiniciar(notificar: false);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _avisarCalificacionPendiente();
      _revisarAvisos();
    });
    _revision = Timer.periodic(_cadaCuanto, (_) => _revisarAvisos());
  }

  @override
  void dispose() {
    _revision?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _shell.removeListener(_alCambiarPestana);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a la app se revisa de inmediato.
    if (state == AppLifecycleState.resumed) _revisarAvisos();
  }

  Future<void> _revisarAvisos() async {
    final estado = WidgetsBinding.instance.lifecycleState;
    if (estado != null && estado != AppLifecycleState.resumed) return;
    final nueva = await _avisos.revisar();
    if (nueva == null || !mounted) return;
    _mostrarAviso(nueva);
  }

  /// Banner dentro de la app cuando llega una notificación nueva.
  void _mostrarAviso(Notificacion n) {
    final mensajero = ScaffoldMessenger.of(context);
    mensajero.hideCurrentSnackBar();
    mensajero.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        backgroundColor: C.card,
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: C.light),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.titulo,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  if ((n.cuerpo ?? '').isNotEmpty)
                    Text(n.cuerpo!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: C.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Ver',
          textColor: C.light,
          onPressed: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const NotificacionesScreen()));
            _avisos.revisar();
          },
        ),
      ),
    );
  }

  void _alCambiarPestana() => setState(() => _abiertas.add(_shell.index));

  /// Como en Uber: al entrar, si hay un trabajo completado sin calificar,
  /// se ofrece calificarlo.
  Future<void> _avisarCalificacionPendiente() async {
    final usuario = context.read<AuthProvider>().usuario;
    if (usuario == null) return;
    try {
      final completadas = await SolicitudService(context.read<ApiClient>())
          .listar(estado: EstadoSolicitud.completado, limite: 10);
      final pendiente = completadas.where((s) => s.porCalificar).firstOrNull;
      if (pendiente == null || !mounted) return;
      await mostrarAvisoCalificacion(context, pendiente, usuario.id);
    } catch (_) {
      // Sin conexión o sin solicitudes: no se muestra nada.
    }
  }

  @override
  Widget build(BuildContext context) {
    final esTrabajador =
        context.select<AuthProvider, bool>((a) => a.usuario?.esTrabajador ?? false);
    final tabs = esTrabajador ? _tabsTrabajador : _tabsCliente;
    final index = _shell.index.clamp(0, tabs.length - 1);

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: [
            for (int i = 0; i < tabs.length; i++)
              _abiertas.contains(i) ? tabs[i].pagina() : const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: C.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: _shell.ir,
          type: BottomNavigationBarType.fixed,
          backgroundColor: C.navy,
          selectedItemColor: C.primary,
          unselectedItemColor: Colors.white,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: [
            for (final t in tabs)
              BottomNavigationBarItem(
                icon: Icon(t.icono),
                activeIcon: Icon(t.iconoActivo),
                label: t.etiqueta,
              ),
          ],
        ),
      ),
    );
  }
}
