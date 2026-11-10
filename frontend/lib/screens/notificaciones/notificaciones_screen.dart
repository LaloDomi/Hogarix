import 'package:flutter/material.dart';
import 'package:manocerca/core/models/conversacion.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/main_shell/shell_controller.dart';
import 'package:manocerca/screens/solicitudes/solicitudes_screen.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/chat_service.dart';
import 'package:provider/provider.dart';

/// Avisos de la app: solicitudes nuevas, cambios de estado y visitas.
class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<Notificacion>? _lista;
  String? _error;

  NotificacionService get _service => NotificacionService(context.read<ApiClient>());

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (_error != null) setState(() => _error = null);
    try {
      final lista = await _service.listar();
      if (mounted) setState(() => _lista = lista);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.mensaje : 'No se pudieron cargar los avisos.');
      }
    }
  }

  Future<void> _marcarTodas() async {
    try {
      await _service.marcarTodas();
      await _cargar();
    } on ApiException catch (e) {
      if (mounted) mostrarAviso(context, e.mensaje);
    }
  }

  IconData _icono(String tipo) => switch (tipo) {
        'solicitud_nueva' => Icons.assignment_add,
        'solicitud_estado' => Icons.assignment_turned_in_outlined,
        'visita' => Icons.event_available,
        _ => Icons.notifications_outlined,
      };

  Future<void> _abrir(Notificacion n) async {
    if (!n.leida) _service.marcarLeida(n.id).catchError((_) {});
    final esTrabajador = context.read<AuthProvider>().usuario?.esTrabajador ?? false;
    final shell = context.read<ShellController>();
    if (n.tipo == 'visita') {
      // El calendario es la pestaña 1 del trabajador y la 2 del cliente.
      Navigator.of(context).popUntil((r) => r.isFirst);
      shell.ir(esTrabajador ? 1 : 2);
      return;
    }
    if (n.tipo.startsWith('solicitud')) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SolicitudesScreen(conAppBar: true)),
      );
    }
    if (mounted) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _lista;
    final hayNoLeidas = lista?.any((n) => !n.leida) ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          if (hayNoLeidas)
            TextButton(onPressed: _marcarTodas, child: const Text('Marcar leídas')),
        ],
      ),
      body: SafeArea(
        child: _error != null
            ? Center(child: EstadoError(mensaje: _error!, onReintentar: _cargar))
            : lista == null
                ? const Center(child: CircularProgressIndicator())
                : lista.isEmpty
                    ? const Center(
                        child: EstadoVacio(
                          icono: Icons.notifications_none,
                          titulo: 'Sin notificaciones',
                          detalle: 'Aquí verás tus solicitudes, visitas y avisos.',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: lista.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: C.border, indent: 72),
                          itemBuilder: (_, i) {
                            final n = lista[i];
                            return ListTile(
                              onTap: () => _abrir(n),
                              tileColor: n.leida ? null : const Color(0x142F8BFF),
                              leading: CircleAvatar(
                                backgroundColor: C.card,
                                child: Icon(_icono(n.tipo), color: C.light),
                              ),
                              title: Text(n.titulo,
                                  style: TextStyle(
                                      fontWeight: n.leida ? FontWeight.w500 : FontWeight.w800)),
                              subtitle: Text(
                                [
                                  if ((n.cuerpo ?? '').isNotEmpty) n.cuerpo!,
                                  if (n.fecha != null) haceCuanto(n.fecha!),
                                ].join('\n'),
                                style: const TextStyle(color: C.muted, fontSize: 12),
                              ),
                              isThreeLine: (n.cuerpo ?? '').isNotEmpty,
                              trailing: n.leida
                                  ? null
                                  : const Icon(Icons.circle, size: 10, color: C.primary),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
