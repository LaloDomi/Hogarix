import 'package:flutter/material.dart';
import 'package:manocerca/core/models/mi_servicio.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/categoria_icono.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/servicios/servicio_form_screen.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/trabajador_service.dart';
import 'package:provider/provider.dart';

/// El trabajador administra los servicios que ofrece y su disponibilidad.
class MisServiciosScreen extends StatefulWidget {
  const MisServiciosScreen({super.key});

  @override
  State<MisServiciosScreen> createState() => _MisServiciosScreenState();
}

class _MisServiciosScreenState extends State<MisServiciosScreen> {
  late final TrabajadorService _service;
  late final int _idUsuario;

  PerfilTrabajador? _perfil;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = TrabajadorService(context.read<ApiClient>());
    _idUsuario = context.read<AuthProvider>().usuario!.id;
    _cargar();
  }

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _cargar({bool mostrarCarga = true}) async {
    if (mostrarCarga) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    try {
      final perfil = await _service.perfil(_idUsuario);
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _error = null;
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar tus servicios.';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirFormulario([MiServicio? servicio]) async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ServicioFormScreen(servicio: servicio)),
    );
    if (guardado == true && mounted) {
      _aviso(servicio == null ? 'Servicio agregado' : 'Servicio actualizado');
      await _cargar(mostrarCarga: false);
    }
  }

  Future<void> _eliminar(MiServicio servicio) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: Text('¿Quieres eliminar "${servicio.categoria}"? Dejarás de aparecer en esa búsqueda.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      await _service.eliminarServicio(servicio.id);
      if (!mounted) return;
      _aviso('Servicio eliminado');
      await _cargar(mostrarCarga: false);
    } on ApiException catch (e) {
      if (mounted) _aviso(e.mensaje);
    } catch (_) {
      if (mounted) _aviso('No se pudo eliminar el servicio.');
    }
  }

  Future<void> _cambiarDisponibilidad(bool valor) async {
    final anterior = _perfil!;
    setState(() => _perfil = PerfilTrabajador(disponible: valor, servicios: anterior.servicios));
    try {
      await _service.actualizarDisponibilidad(valor);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _perfil = anterior);
      _aviso(e.mensaje);
    } catch (_) {
      if (!mounted) return;
      setState(() => _perfil = anterior);
      _aviso('No se pudo actualizar tu disponibilidad.');
    }
  }

  Widget _tarjeta(MiServicio s) {
    final descripcion = s.descripcion?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: cardDeco(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: C.bg2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconoDeCategoria(s.categoria), color: C.light),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.categoria,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(s.precioTexto,
                    style: const TextStyle(
                        color: C.light, fontSize: 13, fontWeight: FontWeight.w600)),
                if (descripcion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: C.muted, fontSize: 12)),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opciones',
            color: C.card,
            onSelected: (accion) =>
                accion == 'editar' ? _abrirFormulario(s) : _eliminar(s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    final perfil = _perfil;
    if (_error != null || perfil == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'No se pudieron cargar tus servicios.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: C.muted, fontSize: 14)),
            TextButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _cargar(mostrarCarga: false),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: cardDeco(),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Disponible para recibir solicitudes',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        perfil.disponible
                            ? 'Los clientes te ven como disponible'
                            : 'Los clientes te ven como no disponible',
                        style: const TextStyle(color: C.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(value: perfil.disponible, onChanged: _cambiarDisponibilidad),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Agregar servicio',
            icon: Icons.add,
            onTap: () => _abrirFormulario(),
          ),
          const SizedBox(height: 20),
          if (perfil.servicios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Aún no ofreces ningún servicio.\nAgrega el primero para aparecer en las búsquedas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: C.muted, fontSize: 14, height: 1.4),
              ),
            )
          else ...[
            for (final s in perfil.servicios) ...[
              _tarjeta(s),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis servicios',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(child: _contenido()),
    );
  }
}
