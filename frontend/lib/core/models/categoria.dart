class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;

  const Categoria({required this.id, required this.nombre, this.descripcion});

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: (json['id_categoria'] as num).toInt(),
        nombre: json['nombre_categoria'] as String,
        descripcion: json['descripcion'] as String?,
      );
}
