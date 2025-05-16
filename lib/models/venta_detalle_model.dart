// lib/models/venta_detalle_model.dart
class VentaDetalle {
  final int ventaId;
  final String comprador;
  final int cantidadVendida;
  final DateTime fecha; // Convertiremos el string de fecha a DateTime
  final int productoId;
  final String nombreProducto;
  final double precioUnitarioEnVenta;
  final double subtotalVenta;

  VentaDetalle({
    required this.ventaId,
    required this.comprador,
    required this.cantidadVendida,
    required this.fecha,
    required this.productoId,
    required this.nombreProducto,
    required this.precioUnitarioEnVenta,
    required this.subtotalVenta,
  });

  factory VentaDetalle.fromJson(Map<String, dynamic> json) {
    return VentaDetalle(
      ventaId: json['venta_id'] as int,
      comprador: json['comprador'] as String,
      cantidadVendida: json['cantidad_vendida'] as int,
      fecha: DateTime.parse(json['fecha'] as String), // MySQL DATETIME a DateTime
      productoId: json['producto_id'] as int,
      nombreProducto: json['nombre_producto'] as String,
      precioUnitarioEnVenta: (json['precio_unitario_en_venta'] as num).toDouble(),
      subtotalVenta: (json['subtotal_venta'] as num).toDouble(),
    );
  }
}