import 'package:flutter/material.dart';
import 'package:manocerca/core/models/evento_agenda.dart';
import 'package:manocerca/core/models/visita.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/screens/agenda/evento_form_screen.dart';
import 'package:manocerca/screens/visitas/agendar_visita_screen.dart';
import 'package:manocerca/screens/visitas/widgets/tarjeta_visita.dart';
import 'package:manocerca/services/agenda_service.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/visita_service.dart';
import 'package:provider/provider.dart';

enum _Vista { calendario, agenda }

/// Calendario de clientes y trabajadores. Muestra las visitas de trabajo
/// (compartidas con la otra persona) y los eventos personales (privados).
/// "Calendario" y "Agenda" son dos vistas de lo mismo.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  static const _diasSemana = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  late final AgendaService _service;
  late final VisitaService _visitasService;
  List<Visita> _visitas = const [];
  late DateTime _mes;
  late DateTime _seleccionado;
  _Vista _vista = _Vista.calendario;

  List<EventoAgenda> _eventos = const [];
  bool _cargando = true;
  String? _error;
  int _peticion = 0;

  @override
  void initState() {
    super.initState();
    _service = AgendaService(context.read<ApiClient>());
    _visitasService = VisitaService(context.read<ApiClient>());
    final hoy = soloDia(DateTime.now());
    _seleccionado = hoy;
    _mes = DateTime(hoy.year, hoy.month);
    _cargar();
  }

  /// Primer día que muestra la cuadrícula (el lunes de la primera semana).
  DateTime get _inicioCuadricula {
    final desfase = (_mes.weekday + 6) % 7;
    return DateTime(_mes.year, _mes.month, 1 - desfase);
  }

  int get _semanas {
    final desfase = (_mes.weekday + 6) % 7;
    final diasDelMes = DateTime(_mes.year, _mes.month + 1, 0).day;
    return ((desfase + diasDelMes) / 7).ceil();
  }

  DateTime get _finCuadricula {
    final i = _inicioCuadricula;
    return DateTime(i.year, i.month, i.day + _semanas * 7);
  }

  Future<void> _cargar({bool mostrarCarga = true}) async {
    final peticion = ++_peticion;
    if (mostrarCarga) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    // Las visitas se piden aparte: si fallan, la agenda personal sigue funcionando.
    _cargarVisitas(peticion);
    try {
      final eventos = await _service.listar(_inicioCuadricula, _finCuadricula);
      if (!mounted || peticion != _peticion) return;
      setState(() {
        _eventos = eventos;
        _error = null;
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
        _error = 'No se pudo cargar tu agenda.';
        _cargando = false;
      });
    }
  }

  Future<void> _cargarVisitas(int peticion) async {
    try {
      final visitas = await _visitasService.listar(_inicioCuadricula, _finCuadricula);
      if (!mounted || peticion != _peticion) return;
      setState(() => _visitas = visitas);
    } catch (_) {
      if (mounted && peticion == _peticion) setState(() => _visitas = const []);
    }
  }

  List<Visita> _visitasDe(DateTime dia) =>
      (_visitas.where((v) => v.ocurreEn(dia)).toList()
        ..sort((a, b) => a.inicio.compareTo(b.inicio)));

  Future<void> _agendarVisita() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AgendarVisitaScreen(dia: _seleccionado)),
    );
    if (ok == true && mounted) await _cargar(mostrarCarga: false);
  }

  Widget _tarjetaVisita(Visita v) {
    final u = context.read<AuthProvider>().usuario;
    return TarjetaVisita(
      visita: v,
      idYo: u?.id ?? 0,
      soyTrabajador: u?.esTrabajador ?? false,
      alCambiar: () => _cargar(mostrarCarga: false),
    );
  }

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _irAMes(DateTime mes) {
    final hoy = soloDia(DateTime.now());
    setState(() {
      _mes = DateTime(mes.year, mes.month);
      _seleccionado = (hoy.year == mes.year && hoy.month == mes.month)
          ? hoy
          : DateTime(mes.year, mes.month, 1);
      _eventos = const [];
      _visitas = const [];
    });
    _cargar();
  }

  List<EventoAgenda> _eventosDe(DateTime dia) =>
      (_eventos.where((e) => e.ocurreEn(dia)).toList()
        ..sort((a, b) => a.inicio.compareTo(b.inicio)));

  Future<void> _abrirFormulario([EventoAgenda? evento]) async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventoFormScreen(dia: _seleccionado, evento: evento),
      ),
    );
    if (guardado == true && mounted) {
      _aviso(evento == null ? 'Evento agregado' : 'Evento actualizado');
      await _cargar(mostrarCarga: false);
    }
  }

  Future<void> _eliminar(EventoAgenda evento) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text('¿Quieres eliminar "${evento.titulo}"?'),
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
      await _service.eliminar(evento.id);
      if (!mounted) return;
      _aviso('Evento eliminado');
      await _cargar(mostrarCarga: false);
    } on ApiException catch (e) {
      if (mounted) _aviso(e.mensaje);
    } catch (_) {
      if (mounted) _aviso('No se pudo eliminar el evento.');
    }
  }

  // ---------------------------------------------------------------- widgets

  Widget _selectorVista() {
    Widget opcion(_Vista v, String texto, IconData icono) {
      final activa = _vista == v;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _vista = v),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: activa ? C.primary : C.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: activa ? C.primary : C.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, size: 18, color: activa ? Colors.white : C.muted),
                const SizedBox(width: 6),
                Text(texto,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: activa ? Colors.white : C.muted)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        opcion(_Vista.calendario, 'Calendario', Icons.calendar_month),
        const SizedBox(width: 10),
        opcion(_Vista.agenda, 'Agenda', Icons.view_agenda_outlined),
      ],
    );
  }

  Widget _encabezadoMes() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Mes anterior',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _irAMes(DateTime(_mes.year, _mes.month - 1)),
        ),
        Expanded(
          child: Text(tituloMes(_mes),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        IconButton(
          tooltip: 'Mes siguiente',
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _irAMes(DateTime(_mes.year, _mes.month + 1)),
        ),
      ],
    );
  }

  Widget _celda(DateTime dia) {
    final fueraDeMes = dia.month != _mes.month;
    final seleccionado = mismoDia(dia, _seleccionado);
    final esHoy = mismoDia(dia, DateTime.now());
    final cantidad = _eventosDe(dia).length;
    final visitas = _visitasDe(dia);
    final porConfirmar = visitas.any((v) => v.estado == EstadoVisita.propuesta);

    return GestureDetector(
      key: ValueKey('dia-${dia.year}-${dia.month}-${dia.day}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _seleccionado = dia),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: seleccionado ? C.primary : null,
          borderRadius: BorderRadius.circular(12),
          border: esHoy && !seleccionado ? Border.all(color: C.primary, width: 1.4) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${dia.day}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: seleccionado || esHoy ? FontWeight.w800 : FontWeight.w500,
                  color: seleccionado
                      ? Colors.white
                      : (fueraDeMes ? C.border : Colors.white),
                )),
            const SizedBox(height: 3),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Visitas: punto verde (confirmada) o amarillo (por confirmar).
                  if (visitas.isNotEmpty)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: porConfirmar ? C.star : C.green,
                      ),
                    ),
                  for (var i = 0; i < cantidad.clamp(0, visitas.isEmpty ? 3 : 2); i++)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: seleccionado ? Colors.white : C.light,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cuadricula() {
    final inicio = _inicioCuadricula;
    return Column(
      children: [
        Row(
          children: [
            for (final d in _diasSemana)
              Expanded(
                child: Center(
                  child: Text(d,
                      style: const TextStyle(
                          color: C.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0,
          children: [
            for (var i = 0; i < _semanas * 7; i++)
              _celda(DateTime(inicio.year, inicio.month, inicio.day + i)),
          ],
        ),
      ],
    );
  }

  Widget _tarjeta(EventoAgenda e) {
    final notas = e.descripcion?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: cardDeco(),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: C.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.titulo,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(e.rangoTexto,
                    style: const TextStyle(
                        color: C.light, fontSize: 13, fontWeight: FontWeight.w600)),
                if (notas.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(notas,
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
            onSelected: (a) => a == 'editar' ? _abrirFormulario(e) : _eliminar(e),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _listaDelDia() {
    final eventos = _eventosDe(_seleccionado);
    final visitas = _visitasDe(_seleccionado);
    return [
      Text(capitalizada(fechaCorta(_seleccionado)),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      for (final v in visitas) ...[_tarjetaVisita(v), const SizedBox(height: 10)],
      if (eventos.isEmpty && visitas.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Text('No tienes eventos este día.',
              style: TextStyle(color: C.muted, fontSize: 14)),
        )
      else
        for (final e in eventos) ...[_tarjeta(e), const SizedBox(height: 10)],
    ];
  }

  bool _delMes(DateTime inicio, bool Function(DateTime) ocurreEn) =>
      inicio.year == _mes.year && inicio.month == _mes.month ||
      ocurreEn(DateTime(_mes.year, _mes.month, 1));

  /// Vista "Agenda": visitas y eventos del mes visible agrupados por día.
  List<Widget> _listaAgenda() {
    final items = <(DateTime, Widget)>[
      for (final v in _visitas)
        if (_delMes(v.inicio, v.ocurreEn)) (v.inicio, _tarjetaVisita(v)),
      for (final e in _eventos)
        if (_delMes(e.inicio, e.ocurreEn)) (e.inicio, _tarjeta(e)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    if (items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Text('No tienes eventos en este mes.',
                style: TextStyle(color: C.muted, fontSize: 14)),
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    DateTime? diaActual;
    for (final (inicio, tarjeta) in items) {
      final dia = soloDia(inicio);
      if (diaActual == null || !mismoDia(dia, diaActual)) {
        diaActual = dia;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 8),
          child: Text(capitalizada(fechaCorta(dia)),
              style: const TextStyle(
                  color: C.muted, fontSize: 13, fontWeight: FontWeight.w700)),
        ));
      }
      widgets..add(tarjeta)..add(const SizedBox(height: 10));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final calendario = _vista == _Vista.calendario;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi agenda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () {
              final hoy = soloDia(DateTime.now());
              if (hoy.year != _mes.year || hoy.month != _mes.month) {
                _irAMes(DateTime(hoy.year, hoy.month));
              }
              setState(() => _seleccionado = hoy);
            },
            child: const Text('Hoy'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _cargar(mostrarCarga: false),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _selectorVista(),
              const SizedBox(height: 12),
              _encabezadoMes(),
              if (_cargando) const LinearProgressIndicator(minHeight: 2),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                TextButton(onPressed: _cargar, child: const Text('Reintentar')),
              ],
              const SizedBox(height: 8),
              if (calendario) ...[
                _cuadricula(),
                const SizedBox(height: 16),
                ..._listaDelDia(),
              ] else
                ..._listaAgenda(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlineButtonX(
                      text: 'Visita',
                      icon: Icons.handshake_outlined,
                      onTap: _agendarVisita,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Agregar evento',
                      icon: Icons.add,
                      onTap: () => _abrirFormulario(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
