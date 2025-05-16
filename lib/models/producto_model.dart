// lib/models/producto_model.dart (o dentro de registro_venta_screen.dart)
class Producto {
  final int id;
  final String nombre;
  final double precio;
  int cantidad; // Mutable para actualizarla en UI si es necesario después de una venta

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidad,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      cantidad: json['cantidad'] as int,
    );
  }

  // Para mostrar en el Dropdown
  @override
  String toString() => nombre;
}