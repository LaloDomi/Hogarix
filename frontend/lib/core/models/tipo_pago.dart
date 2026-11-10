/// Tipos de pago: etiqueta que ve el usuario y valor que entiende el backend.
class TipoPago {
  final String etiqueta;
  final String valor;
  const TipoPago(this.etiqueta, this.valor);

  static const todos = <TipoPago>[
    TipoPago('Por día', 'Día'),
    TipoPago('Destajo', 'Destajo'),
    TipoPago('Por trabajo', 'Por trabajo'),
    TipoPago('Por hora', 'Por hora'),
  ];
}
