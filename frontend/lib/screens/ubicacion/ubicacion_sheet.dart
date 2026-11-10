import 'package:flutter/material.dart';
import 'package:manocerca/core/data/ubicaciones_mx.dart';
import 'package:manocerca/core/theme/app_theme.dart';
import 'package:manocerca/core/theme/colors.dart';
import 'package:manocerca/core/utils/texto.dart';
import 'package:manocerca/core/widgets/estados.dart';
import 'package:manocerca/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Abre el panel para elegir la ubicación a mano (estado, municipio y colonia)
/// y la guarda en el perfil. Devuelve `true` si se guardó.
/// Más adelante se puede agregar el GPS; por ahora es manual.
Future<bool> editarUbicacion(BuildContext context) async {
  final guardado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.bg2,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _UbicacionSheet(),
  );
  if (guardado == true && context.mounted) mostrarAviso(context, 'Ubicación actualizada');
  return guardado ?? false;
}

class _UbicacionSheet extends StatefulWidget {
  const _UbicacionSheet();

  @override
  State<_UbicacionSheet> createState() => _UbicacionSheetState();
}

class _UbicacionSheetState extends State<_UbicacionSheet> {
  String? _estado;
  final _municipio = TextEditingController();
  final _colonia = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().usuario;
    _estado = ubicacionesMx.containsKey(u?.estadoMx) ? u!.estadoMx : null;
    _municipio.text = u?.municipio ?? '';
    _colonia.text = u?.colonia ?? '';
  }

  @override
  void dispose() {
    _municipio.dispose();
    _colonia.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_estado == null) {
      setState(() => _error = 'Elige tu estado');
      return;
    }
    if (_municipio.text.trim().isEmpty) {
      setState(() => _error = 'Escribe tu municipio o ciudad');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await context.read<AuthProvider>().actualizarPerfil({
      'estado_mx': _estado,
      'municipio': _municipio.text.trim(),
      'colonia': _colonia.text.trim(),
    });
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _guardando = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sugerencias = ubicacionesMx[_estado] ?? const <String>[];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: C.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.location_on, color: C.primary),
                  SizedBox(width: 8),
                  Text('Tu ubicación',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'La usamos para mostrarte profesionales de tu zona y como dirección '
                'sugerida en tus visitas.',
                style: TextStyle(color: C.muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: _estado,
                isExpanded: true,
                dropdownColor: C.card,
                menuMaxHeight: 360,
                decoration: inputDeco('Estado'),
                items: [
                  for (final e in ubicacionesMx.keys)
                    DropdownMenuItem(value: e, child: Text(e)),
                ],
                onChanged: _guardando
                    ? null
                    : (v) => setState(() {
                          if (v != _estado) _municipio.clear();
                          _estado = v;
                        }),
              ),
              const SizedBox(height: 12),
              // Sugerencias del estado elegido; se puede escribir cualquier municipio.
              Autocomplete<String>(
                key: ValueKey(_estado),
                initialValue: TextEditingValue(text: _municipio.text),
                optionsBuilder: (v) {
                  final q = normalizar(v.text);
                  if (q.isEmpty) return sugerencias;
                  return sugerencias.where((s) => normalizar(s).contains(q));
                },
                onSelected: (s) => _municipio.text = s,
                fieldViewBuilder: (context, controller, foco, alEnviar) => TextField(
                  controller: controller,
                  focusNode: foco,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (v) => _municipio.text = v,
                  decoration: inputDeco('Municipio o ciudad',
                      prefix: const Icon(Icons.location_city, color: C.muted)),
                ),
                optionsViewBuilder: (context, alElegir, opciones) => Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: C.card,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220, maxWidth: 420),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: [
                          for (final o in opciones)
                            ListTile(
                              dense: true,
                              title: Text(o),
                              onTap: () => alElegir(o),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _colonia,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.words,
                decoration: inputDeco('Colonia (opcional)',
                    prefix: const Icon(Icons.home_outlined, color: C.muted)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Guardar ubicación',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pronto podrás usar la ubicación de tu teléfono (GPS).',
                textAlign: TextAlign.center,
                style: TextStyle(color: C.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
