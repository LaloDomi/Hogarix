/// "$150 por hora", "$500 por día" o "Precio a convenir".
String textoPrecio(double? precio, String? tipoPago) {
  if (precio == null) return 'Precio a convenir';
  final monto = precio == precio.roundToDouble()
      ? precio.toStringAsFixed(0)
      : precio.toStringAsFixed(2);
  final sufijo = switch (tipoPago) {
    'Día' => ' por día',
    'Por hora' => ' por hora',
    'Por trabajo' => ' por trabajo',
    'Destajo' => ' a destajo',
    _ => '',
  };
  return '\$$monto$sufijo';
}
