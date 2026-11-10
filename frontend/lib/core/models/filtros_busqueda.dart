import 'package:manocerca/core/models/pro.dart';
import 'package:manocerca/core/utils/texto.dart';

enum OrdenBusqueda {
  recomendados('Recomendados'),
  mejorCalificados('Mejor calificados'),
  masResenas('Más reseñas'),
  menorPrecio('Menor precio'),
  mayorPrecio('Mayor precio');

  final String etiqueta;
  const OrdenBusqueda(this.etiqueta);
}

/// Filtros de la pantalla Buscar. Todo se aplica en el teléfono sobre los
/// resultados del backend, así la lista cambia al instante mientras se escribe.
class FiltrosBusqueda {
  final String texto;

  /// null = todas las categorías.
  final int? idCategoria;

  /// Valor del backend: 'Día', 'Destajo', 'Por trabajo', 'Por hora' (null = todos).
  final String? tipoPago;
  final double? precioMin;
  final double? precioMax;

  /// 0 = cualquiera.
  final double calificacionMin;
  final bool soloDisponibles;
  final OrdenBusqueda orden;

  /// Solo profesionales de mi estado (según la ubicación de mi perfil).
  final bool soloMiZona;

  /// Mi ubicación: no es un filtro del panel, sirve para "En mi zona" y para
  /// poner primero a los de mi municipio.
  final String? miEstado;
  final String? miMunicipio;

  const FiltrosBusqueda({
    this.texto = '',
    this.idCategoria,
    this.tipoPago,
    this.precioMin,
    this.precioMax,
    this.calificacionMin = 0,
    this.soloDisponibles = false,
    this.orden = OrdenBusqueda.recomendados,
    this.soloMiZona = false,
    this.miEstado,
    this.miMunicipio,
  });

  /// Cuántos filtros del panel están activos (para el número del botón).
  int get activos => [
        tipoPago != null,
        precioMin != null || precioMax != null,
        calificacionMin > 0,
        soloDisponibles,
        orden != OrdenBusqueda.recomendados,
        soloMiZona,
      ].where((x) => x).length;

  FiltrosBusqueda copyWith({
    String? texto,
    int? Function()? idCategoria,
    String? Function()? tipoPago,
    double? Function()? precioMin,
    double? Function()? precioMax,
    double? calificacionMin,
    bool? soloDisponibles,
    OrdenBusqueda? orden,
    bool? soloMiZona,
    String? Function()? miEstado,
    String? Function()? miMunicipio,
  }) =>
      FiltrosBusqueda(
        texto: texto ?? this.texto,
        idCategoria: idCategoria != null ? idCategoria() : this.idCategoria,
        tipoPago: tipoPago != null ? tipoPago() : this.tipoPago,
        precioMin: precioMin != null ? precioMin() : this.precioMin,
        precioMax: precioMax != null ? precioMax() : this.precioMax,
        calificacionMin: calificacionMin ?? this.calificacionMin,
        soloDisponibles: soloDisponibles ?? this.soloDisponibles,
        orden: orden ?? this.orden,
        soloMiZona: soloMiZona ?? this.soloMiZona,
        miEstado: miEstado != null ? miEstado() : this.miEstado,
        miMunicipio: miMunicipio != null ? miMunicipio() : this.miMunicipio,
      );

  /// Quita los filtros del panel y conserva texto y categoría.
  FiltrosBusqueda limpiarPanel() => FiltrosBusqueda(
        texto: texto,
        idCategoria: idCategoria,
        miEstado: miEstado,
        miMunicipio: miMunicipio,
      );

  bool _mismoEstado(Pro p) =>
      miEstado != null && p.estadoMx != null && normalizar(p.estadoMx!) == normalizar(miEstado!);

  bool _mismoMunicipio(Pro p) =>
      miMunicipio != null &&
      p.municipio != null &&
      normalizar(p.municipio!) == normalizar(miMunicipio!);

  bool _coincideTexto(Pro p) {
    final q = normalizar(texto);
    if (q.isEmpty) return true;
    final donde = normalizar('${p.name} ${p.categoria ?? ''} ${p.descripcion ?? ''}');
    // Todas las palabras deben aparecer, en cualquier orden.
    return q.split(RegExp(r'\s+')).every(donde.contains);
  }

  bool acepta(Pro p) {
    if (idCategoria != null && p.idCategoria != idCategoria) return false;
    if (tipoPago != null && p.tipoPago != tipoPago) return false;
    if (soloDisponibles && !p.disponible) return false;
    if (soloMiZona && miEstado != null && !_mismoEstado(p)) return false;
    if (calificacionMin > 0 && (p.rating ?? 0) < calificacionMin) return false;
    if (precioMin != null && (p.precioBase == null || p.precioBase! < precioMin!)) return false;
    if (precioMax != null && (p.precioBase == null || p.precioBase! > precioMax!)) return false;
    return _coincideTexto(p);
  }

  List<Pro> aplicar(Iterable<Pro> pros) {
    final lista = pros.where(acepta).toList();
    int porPrecio(Pro a, Pro b, {bool desc = false}) {
      // Los "a convenir" siempre al final.
      if (a.precioBase == null && b.precioBase == null) return 0;
      if (a.precioBase == null) return 1;
      if (b.precioBase == null) return -1;
      return desc ? b.precioBase!.compareTo(a.precioBase!) : a.precioBase!.compareTo(b.precioBase!);
    }

    switch (orden) {
      case OrdenBusqueda.recomendados:
        // Disponibles y cercanos primero, luego por calificación y reseñas.
        double puntaje(Pro p) =>
            (p.disponible ? 10.0 : 0.0) +
            (_mismoMunicipio(p) ? 6.0 : (_mismoEstado(p) ? 3.0 : 0.0)) +
            (p.rating ?? 0.0) +
            (p.reviews / 100);
        lista.sort((a, b) => puntaje(b).compareTo(puntaje(a)));
      case OrdenBusqueda.mejorCalificados:
        lista.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      case OrdenBusqueda.masResenas:
        lista.sort((a, b) => b.reviews.compareTo(a.reviews));
      case OrdenBusqueda.menorPrecio:
        lista.sort(porPrecio);
      case OrdenBusqueda.mayorPrecio:
        lista.sort((a, b) => porPrecio(a, b, desc: true));
    }
    return lista;
  }
}
