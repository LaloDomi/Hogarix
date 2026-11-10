import 'package:flutter/material.dart';
import 'package:manocerca/core/models/solicitud.dart';
import 'package:manocerca/core/models/visita.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/solicitud_service.dart';
import 'package:manocerca/services/visita_service.dart';
import 'package:provider/provider.dart';

/// Proponer una visita de trabajo (o un nuevo horario para una existente).
/// La otra persona la confirma desde su calendario. Devuelve `true` si se guardó.
class AgendarVisitaScreen extends StatefulWidget {
  /// Solicitud de la visita. Si es null (y no hay [visita]), se elige de la lista.
  final Solicitud? solicitud;

  /// Visita a reprogramar.
  final Visita? visita;

  /// Día sugerido (p. ej. el que estaba seleccionado en el calendario).
  final DateTime? dia;

  const AgendarVisitaScreen({super.key, this.solicitud, this.visita, this.dia});

  @override
  State<AgendarVisitaScreen> createState() => _AgendarVisitaScreenState();
}

class _AgendarVisitaScreenState extends State<AgendarVisitaScreen> {
  late DateTime _dia;
  late TimeOfDay _inicio;
  late TimeOfDay _fin;
  final _direccion = TextEditingController();
  final _notas = TextEditingController();

  Solicitud? _solicitud;
  List<Solicitud>? _opciones;
  String? _errorOpciones;
  bool _guardando = false;

  bool get _reprogramando => widget.visita != null;

  @override
  void initState() {
    super.initState();
    final v = widget.visita;
    final manana = soloDia(DateTime.now()).add(const Duration(days: 1));
    final sugerido = widget.dia != null && !soloDia(widget.dia!).isBefore(soloDia(DateTime.now()))
        ? soloDia(widget.dia!)
        : manana;
    _dia = v != null ? soloDia(v.inicio) : sugerido;
    _inicio = v != null ? TimeOfDay.fromDateTime(v.inicio) : const TimeOfDay(hour: 10, minute: 0);
    _fin = v != null ? TimeOfDay.fromDateTime(v.fin) : const TimeOfDay(hour: 12, minute: 0);
    _direccion.text = v?.direccion ?? '';
    _notas.text = v?.notas ?? '';
    _solicitud = widget.solicitud;
    if (_solicitud != null) _sugerirDireccion(_solicitud!);
    if (!_reprogramando && _solicitud == null) _cargarOpciones();
  }

  @override
  void dispose() {
    _direccion.dispose();
    _notas.dispose();
    super.dispose();
  }

  /// La visita es en casa del cliente: se propone su ubicación.
  void _sugerirDireccion(Solicitud s) {
    if (_direccion.text.trim().isNotEmpty) return;
    final yo = context.read<AuthProvider>().usuario;
    final deCliente = s.ubicacionCliente ??
        (yo != null && yo.id == s.idCliente ? yo.ubicacionTexto : null);
    if (deCliente != null) _direccion.text = deCliente;
  }

  Future<void> _cargarOpciones() async {
    try {
      final todas = await SolicitudService(context.read<ApiClient>()).listar();
      final activas = todas.where((s) => s.activa).toList();
      if (!mounted) return;
      setState(() {
        _opciones = activas;
        if (activas.length == 1) {
          _solicitud = activas.first;
          _sugerirDireccion(activas.first);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _errorOpciones =
            e is ApiException ? e.mensaje : 'No se pudieron cargar tus solicitudes.');
      }
    }
  }

  DateTime _con(TimeOfDay t) => DateTime(_dia.year, _dia.month, _dia.day, t.hour, t.minute);
  int _min(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _elegirDia() async {
    final hoy = soloDia(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _dia.isBefore(hoy) ? hoy : _dia,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
      helpText: 'Día de la visita',
    );
    if (d != null) setState(() => _dia = d);
  }

  Future<void> _elegirHora(bool esInicio) async {
    final t = await showTimePicker(
      context: context,
      initialTime: esInicio ? _inicio : _fin,
      helpText: esInicio ? 'Hora de llegada' : 'Hora de término',
    );
    if (t == null) return;
    setState(() {
      if (esInicio) {
        final duracion = _min(_fin) - _min(_inicio);
        _inicio = t;
        // Conserva la duración al mover la hora de inicio.
        final finMin = (_min(t) + (duracion > 0 ? duracion : 60)).clamp(0, 23 * 60 + 59);
        _fin = TimeOfDay(hour: finMin ~/ 60, minute: finMin % 60);
      } else {
        _fin = t;
      }
    });
  }

  Future<void> _guardar() async {
    final s = _solicitud;
    if (!_reprogramando && s == null) {
      mostrarAviso(context, 'Elige la solicitud de la visita');
      return;
    }
    final inicio = _con(_inicio);
    final fin = _con(_fin);
    if (!fin.isAfter(inicio)) {
      mostrarAviso(context, 'La hora de término debe ser después de la de llegada');
      return;
    }
    if (inicio.isBefore(DateTime.now())) {
      mostrarAviso(context, 'Elige un horario que todavía no haya pasado');
      return;
    }
    setState(() => _guardando = true);
    final service = VisitaService(context.read<ApiClient>());
    try {
      if (_reprogramando) {
        await service.reprogramar(widget.visita!.id,
            inicio: inicio, fin: fin, direccion: _direccion.text.trim(), notas: _notas.text.trim());
      } else {
        await service.crear(
            idSolicitud: s!.id,
            inicio: inicio,
            fin: fin,
            direccion: _direccion.text.trim(),
            notas: _notas.text.trim());
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      mostrarAviso(context, _reprogramando
          ? 'Nuevo horario enviado. Falta que la otra persona lo confirme.'
          : 'Visita propuesta. Falta que la otra persona la confirme.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarAviso(context, e.mensaje);
    }
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );

  Widget _campo(IconData icono, String etiqueta, String valor, VoidCallback onTap,
          {Key? key}) =>
      InkWell(
        key: key,
        borderRadius: BorderRadius.circular(12),
        onTap: _guardando ? null : onTap,
        child: InputDecorator(
          decoration: inputDeco(etiqueta, prefix: Icon(icono, color: C.muted)),
          child: Text(valor, style: const TextStyle(fontSize: 15)),
        ),
      );

  Widget _selectorSolicitud(int idYo) {
    if (_reprogramando) {
      final v = widget.visita!;
      final otro = v.contraparte(idYo);
      return _tarjetaPersona(otro.nombre, otro.foto, v.categoria);
    }
    if (widget.solicitud != null) {
      final otro = widget.solicitud!.contraparte(idYo);
      return _tarjetaPersona(otro.nombre, otro.foto, widget.solicitud!.categoria);
    }
    if (_errorOpciones != null) {
      return EstadoError(mensaje: _errorOpciones!, onReintentar: () {
        setState(() => _errorOpciones = null);
        _cargarOpciones();
      });
    }
    final opciones = _opciones;
    if (opciones == null) return const LinearProgressIndicator(minHeight: 2);
    if (opciones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDeco(14),
        child: const Text(
          'Para agendar una visita primero necesitas una solicitud pendiente o aceptada.',
          style: TextStyle(color: C.muted),
        ),
      );
    }
    return DropdownButtonFormField<int>(
      value: _solicitud?.id,
      isExpanded: true,
      dropdownColor: C.card,
      decoration: inputDeco('¿Con quién es la visita?'),
      items: [
        for (final s in opciones)
          DropdownMenuItem(
            value: s.id,
            child: Text('${s.contraparte(idYo).nombre} · ${s.categoria}',
                overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: _guardando
          ? null
          : (id) {
              final s = opciones.firstWhere((x) => x.id == id);
              setState(() => _solicitud = s);
              _sugerirDireccion(s);
            },
    );
  }

  Widget _tarjetaPersona(String nombre, String? foto, String categoria) => Container(
        padding: const EdgeInsets.all(12),
        decoration: cardDeco(14),
        child: Row(
          children: [
            Avatar(name: nombre, foto: urlFoto(context, foto), size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(categoria, style: const TextStyle(color: C.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final idYo = context.read<AuthProvider>().usuario?.id ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(_reprogramando ? 'Cambiar horario' : 'Agendar visita',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _selectorSolicitud(idYo),
            _titulo('¿Cuándo?'),
            _campo(Icons.event, 'Día', capitalizada(fechaLarga(_dia)), _elegirDia),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _campo(Icons.schedule, 'Llegada', _inicio.format(context),
                      () => _elegirHora(true)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _campo(Icons.schedule_outlined, 'Término', _fin.format(context),
                      () => _elegirHora(false)),
                ),
              ],
            ),
            _titulo('¿Dónde?'),
            TextField(
              controller: _direccion,
              enabled: !_guardando,
              maxLength: 255,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDeco('Dirección o punto de encuentro',
                  prefix: const Icon(Icons.place_outlined, color: C.muted)),
            ),
            TextField(
              controller: _notas,
              enabled: !_guardando,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDeco('Notas: qué revisar, materiales, referencias…'),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x222F8BFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: C.light, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La visita aparece en el calendario de los dos. Queda confirmada '
                      'cuando la otra persona la acepta.',
                      style: TextStyle(color: Color(0xFFD7E0F2), fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _guardando
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    text: _reprogramando ? 'Enviar nuevo horario' : 'Proponer visita',
                    icon: Icons.send,
                    onTap: _guardar,
                  ),
          ],
        ),
      ),
    );
  }
}
