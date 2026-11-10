import 'package:flutter/material.dart';
import 'package:manocerca/core/models/evento_agenda.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/services/agenda_service.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:provider/provider.dart';

/// Crea un evento en [dia] o edita [evento]. Al guardar hace `pop(true)`.
class EventoFormScreen extends StatefulWidget {
  final DateTime dia;
  final EventoAgenda? evento;
  const EventoFormScreen({super.key, required this.dia, this.evento});

  @override
  State<EventoFormScreen> createState() => _EventoFormScreenState();
}

class _EventoFormScreenState extends State<EventoFormScreen> {
  static const _finDelDia = 23 * 60 + 59;

  final _form = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _descripcion;
  late DateTime _fecha;
  late int _inicioMin;
  late int _finMin;
  bool _guardando = false;
  String? _error;

  bool get _edita => widget.evento != null;

  @override
  void initState() {
    super.initState();
    final e = widget.evento;
    _titulo = TextEditingController(text: e?.titulo ?? '');
    _descripcion = TextEditingController(text: e?.descripcion ?? '');
    if (e == null) {
      _fecha = soloDia(widget.dia);
      _inicioMin = 9 * 60;
      _finMin = 10 * 60;
    } else {
      _fecha = soloDia(e.inicio);
      _inicioMin = e.inicio.hour * 60 + e.inicio.minute;
      // El formulario maneja eventos de un solo día.
      _finMin = mismoDia(e.inicio, e.fin) ? e.fin.hour * 60 + e.fin.minute : _finDelDia;
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  /// Cada 30 minutos, más el valor actual si no cae en la cuadrícula.
  List<int> _opciones(int actual) {
    final valores = <int>{for (var m = 0; m < 24 * 60; m += 30) m, _finDelDia, actual}.toList()
      ..sort();
    return valores;
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(ahora.year - 1),
      lastDate: DateTime(ahora.year + 3, 12, 31),
    );
    if (elegida != null) setState(() => _fecha = soloDia(elegida));
  }

  void _cambiarInicio(int? minutos) {
    if (minutos == null) return;
    setState(() {
      _inicioMin = minutos;
      if (_finMin <= _inicioMin) {
        _finMin = (_inicioMin + 60).clamp(0, _finDelDia);
      }
    });
  }

  DateTime _fechaConMinutos(int minutos) =>
      DateTime(_fecha.year, _fecha.month, _fecha.day, minutos ~/ 60, minutos % 60);

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final titulo = _titulo.text.trim();
    final descripcion = _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim();
    final inicio = _fechaConMinutos(_inicioMin);
    final fin = _fechaConMinutos(_finMin);

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final service = AgendaService(context.read<ApiClient>());
      if (_edita) {
        await service.actualizar(widget.evento!.id,
            titulo: titulo, inicio: inicio, fin: fin, descripcion: descripcion);
      } else {
        await service.crear(titulo: titulo, inicio: inicio, fin: fin, descripcion: descripcion);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _guardando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo guardar el evento. Intenta de nuevo.';
        _guardando = false;
      });
    }
  }

  Widget _hora(String etiqueta, int valor, ValueChanged<int?> alCambiar,
      {String? Function(int?)? validar, Key? clave}) {
    return DropdownButtonFormField<int>(
      key: clave,
      initialValue: valor,
      isExpanded: true,
      dropdownColor: C.card,
      decoration: inputDeco(etiqueta),
      items: [
        for (final m in _opciones(valor))
          DropdownMenuItem(value: m, child: Text(minutosATexto(m))),
      ],
      onChanged: alCambiar,
      validator: validar,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_edita ? 'Editar evento' : 'Nuevo evento',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titulo,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 150,
                  decoration: inputDeco('Título (ej. Instalación de cocina)'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Escribe un título' : null,
                ),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _elegirFecha,
                  child: InputDecorator(
                    decoration: inputDeco('Fecha',
                        prefix: const Icon(Icons.event, color: C.muted)),
                    child: Text(fechaLarga(_fecha), style: const TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _hora('Desde', _inicioMin, _cambiarInicio,
                          clave: const ValueKey('hora-inicio')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _hora(
                        'Hasta',
                        _finMin,
                        (v) => setState(() => _finMin = v ?? _finMin),
                        clave: ValueKey('hora-fin-$_finMin'),
                        validar: (v) => (v ?? 0) <= _inicioMin
                            ? 'Debe ser posterior al inicio'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descripcion,
                  maxLines: 3,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: inputDeco('Notas (opcional)'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                ],
                const SizedBox(height: 20),
                _guardando
                    ? const SizedBox(
                        height: 50, child: Center(child: CircularProgressIndicator()))
                    : PrimaryButton(
                        text: _edita ? 'Guardar cambios' : 'Agregar evento',
                        onTap: _guardar,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
