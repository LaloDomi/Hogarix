import 'package:flutter/material.dart';
import 'package:manocerca/core/models/filtros_busqueda.dart';
import 'package:manocerca/core/models/tipo_pago.dart';
import 'package:manocerca/core/theme/colors.dart';

/// Panel inferior con los filtros avanzados. Devuelve los filtros elegidos
/// o null si se cerró sin aplicar.
Future<FiltrosBusqueda?> mostrarFiltros(
  BuildContext context, {
  required FiltrosBusqueda actuales,
  required double precioTope,
}) {
  return showModalBottomSheet<FiltrosBusqueda>(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.bg2,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FiltrosSheet(actuales: actuales, precioTope: precioTope),
  );
}

class _FiltrosSheet extends StatefulWidget {
  final FiltrosBusqueda actuales;
  final double precioTope;
  const _FiltrosSheet({required this.actuales, required this.precioTope});

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late FiltrosBusqueda _f = widget.actuales;

  double get _tope => widget.precioTope <= 0 ? 1000 : widget.precioTope;

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      );

  String _monto(double v) => '\$${v.round()}';

  @override
  Widget build(BuildContext context) {
    final rango = RangeValues(
      (_f.precioMin ?? 0.0).clamp(0.0, _tope),
      (_f.precioMax ?? _tope).clamp(0.0, _tope),
    );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text('Filtros',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _f = _f.limpiarPanel()),
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
              _titulo('Ordenar por'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in OrdenBusqueda.values)
                    ChoiceChip(
                      label: Text(o.etiqueta),
                      selected: _f.orden == o,
                      onSelected: (_) => setState(() => _f = _f.copyWith(orden: o)),
                    ),
                ],
              ),
              _titulo('Calificación mínima'),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in const [0.0, 3.0, 4.0, 4.5])
                    ChoiceChip(
                      avatar: c == 0 ? null : const Icon(Icons.star_rounded, color: C.star, size: 16),
                      label: Text(c == 0 ? 'Cualquiera' : '${c == c.roundToDouble() ? c.toInt() : c}+'),
                      selected: _f.calificacionMin == c,
                      onSelected: (_) => setState(() => _f = _f.copyWith(calificacionMin: c)),
                    ),
                ],
              ),
              _titulo('Forma de cobro'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _f.tipoPago == null,
                    onSelected: (_) => setState(() => _f = _f.copyWith(tipoPago: () => null)),
                  ),
                  for (final t in TipoPago.todos)
                    ChoiceChip(
                      label: Text(t.etiqueta),
                      selected: _f.tipoPago == t.valor,
                      onSelected: (_) =>
                          setState(() => _f = _f.copyWith(tipoPago: () => t.valor)),
                    ),
                ],
              ),
              _titulo('Precio'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_monto(rango.start), style: const TextStyle(color: C.muted)),
                  Text(
                    _f.precioMax == null ? '${_monto(_tope)} o más' : _monto(rango.end),
                    style: const TextStyle(color: C.muted),
                  ),
                ],
              ),
              RangeSlider(
                values: rango,
                min: 0,
                max: _tope,
                divisions: 20,
                labels: RangeLabels(_monto(rango.start), _monto(rango.end)),
                onChanged: (v) => setState(() {
                  _f = _f.copyWith(
                    precioMin: () => v.start <= 0 ? null : v.start,
                    precioMax: () => v.end >= _tope ? null : v.end,
                  );
                }),
              ),
              const Text('Al filtrar por precio se ocultan los de "precio a convenir".',
                  style: TextStyle(color: C.muted, fontSize: 11)),
              const SizedBox(height: 8),
              if (_f.miEstado != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _f.soloMiZona,
                  onChanged: (v) => setState(() => _f = _f.copyWith(soloMiZona: v)),
                  title: Text('Solo en ${_f.miEstado}'),
                  subtitle: const Text('Según la ubicación de tu perfil',
                      style: TextStyle(color: C.muted, fontSize: 12)),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _f.soloDisponibles,
                onChanged: (v) => setState(() => _f = _f.copyWith(soloDisponibles: v)),
                title: const Text('Solo disponibles'),
                subtitle: const Text('Profesionales que están tomando trabajos',
                    style: TextStyle(color: C.muted, fontSize: 12)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _f),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Aplicar filtros',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
