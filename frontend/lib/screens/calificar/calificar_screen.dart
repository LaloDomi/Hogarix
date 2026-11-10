import 'package:flutter/material.dart';
import 'package:manocerca/core/models/solicitud.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/fechas.dart';
import 'package:manocerca/core/widgets/avatar.dart';
import 'package:manocerca/core/widgets/buttons.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/core/widgets/imagen_red.dart';
import 'package:manocerca/core/widgets/rating.dart';
import 'package:manocerca/services/api_client.dart';
import 'package:manocerca/services/resena_service.dart';
import 'package:provider/provider.dart';

/// Calificación al estilo Uber: estrellas, etiquetas rápidas y comentario.
/// Sirve en los dos sentidos: el cliente califica al trabajador y el
/// trabajador califica al cliente. Devuelve `true` si se envió.
class CalificarScreen extends StatefulWidget {
  final Solicitud solicitud;
  final int idYo;
  final int estrellasIniciales;

  const CalificarScreen({
    super.key,
    required this.solicitud,
    required this.idYo,
    this.estrellasIniciales = 0,
  });

  @override
  State<CalificarScreen> createState() => _CalificarScreenState();
}

class _CalificarScreenState extends State<CalificarScreen> {
  // Etiquetas para calificar a un trabajador.
  static const _buenasTrabajador = [
    'Puntual', 'Buen trato', 'Trabajo limpio', 'Precio justo', 'Rápido', 'Recomendable',
  ];
  static const _malasTrabajador = [
    'Impuntual', 'Trabajo incompleto', 'Mala comunicación', 'Precio elevado', 'Dejó sucio',
  ];
  // Etiquetas para calificar a un cliente.
  static const _buenasCliente = [
    'Amable', 'Pagó a tiempo', 'Indicaciones claras', 'Respetuoso', 'Puntual',
  ];
  static const _malasCliente = [
    'Pago tardío', 'Cambió lo acordado', 'Poco claro', 'No estaba disponible',
  ];

  late int _estrellas = widget.estrellasIniciales;
  final Set<String> _etiquetas = {};
  final _comentario = TextEditingController();
  bool _enviando = false;

  bool get _calificoATrabajador => widget.idYo == widget.solicitud.idCliente;

  List<String> get _opciones {
    final buena = _estrellas >= 4;
    if (_calificoATrabajador) return buena ? _buenasTrabajador : _malasTrabajador;
    return buena ? _buenasCliente : _malasCliente;
  }

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  void _elegirEstrellas(int valor) {
    final antesBuena = _estrellas >= 4;
    setState(() {
      _estrellas = valor;
      // Si cambia de "buena" a "mala" (o al revés) las etiquetas ya no aplican.
      if (antesBuena != (valor >= 4)) _etiquetas.clear();
    });
  }

  Future<void> _enviar() async {
    if (_estrellas == 0) {
      mostrarAviso(context, 'Elige de 1 a 5 estrellas');
      return;
    }
    final partes = [
      if (_etiquetas.isNotEmpty) _etiquetas.join(' · '),
      if (_comentario.text.trim().isNotEmpty) _comentario.text.trim(),
    ];
    setState(() => _enviando = true);
    try {
      await ResenaService(context.read<ApiClient>()).calificar(
        idSolicitud: widget.solicitud.id,
        calificacion: _estrellas,
        comentario: partes.isEmpty ? null : partes.join('. '),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      mostrarAviso(context, '¡Gracias por tu calificación!');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarAviso(context, e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.solicitud;
    final otro = s.contraparte(widget.idYo);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Center(
              child: Avatar(
                name: otro.nombre,
                foto: urlFoto(context, otro.foto),
                size: 96,
                borde: C.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _calificoATrabajador
                  ? '¿Cómo fue el servicio de ${otro.nombre}?'
                  : '¿Cómo fue trabajar con ${otro.nombre}?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              [s.categoria, if (s.fecha != null) fechaCorta(s.fecha!)].join(' · '),
              textAlign: TextAlign.center,
              style: const TextStyle(color: C.muted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            SelectorEstrellas(valor: _estrellas, onChanged: _elegirEstrellas),
            const SizedBox(height: 8),
            Text(
              textoCalificacion(_estrellas),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _estrellas == 0 ? C.muted : C.star,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _estrellas == 0
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          _estrellas >= 4 ? '¿Qué te gustó?' : '¿Qué se puede mejorar?',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final e in _opciones)
                              FilterChip(
                                label: Text(e),
                                selected: _etiquetas.contains(e),
                                onSelected: (v) => setState(
                                    () => v ? _etiquetas.add(e) : _etiquetas.remove(e)),
                                backgroundColor: C.card,
                                selectedColor: C.primary,
                                checkmarkColor: Colors.white,
                                side: const BorderSide(color: C.border),
                                labelStyle: const TextStyle(fontSize: 13),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _comentario,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: inputDeco('Cuéntanos más (opcional)'),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _enviando
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    text: 'Enviar calificación',
                    icon: Icons.send_rounded,
                    onTap: _enviar,
                  ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _enviando ? null : () => Navigator.pop(context, false),
              child: const Text('Ahora no', style: TextStyle(color: C.muted)),
            ),
          ],
        ),
      ),
    );
  }
}
