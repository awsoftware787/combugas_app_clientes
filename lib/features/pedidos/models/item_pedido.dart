final class ItemPedido {
  const ItemPedido({
    required this.productoId,
    required this.descripcion,
    required this.cantidad,
    required this.importeCentavos,
    required this.fecha,
    required this.servicioId,
    required this.presentacion,
  });

  final int productoId;
  final String descripcion;
  final double cantidad;
  final int importeCentavos;
  final DateTime fecha;
  final int servicioId;
  final String presentacion;

  bool get esCroqueta => servicioId == 9;

  ItemPedido copyWith({
    String? descripcion,
    double? cantidad,
    int? importeCentavos,
    DateTime? fecha,
    String? presentacion,
  }) => ItemPedido(
    productoId: productoId,
    descripcion: descripcion ?? this.descripcion,
    cantidad: cantidad ?? this.cantidad,
    importeCentavos: importeCentavos ?? this.importeCentavos,
    fecha: fecha ?? this.fecha,
    servicioId: servicioId,
    presentacion: presentacion ?? this.presentacion,
  );

  factory ItemPedido.fromJson(Map<String, dynamic> json) => ItemPedido(
    productoId: _asInt(json['claveProducto']),
    descripcion: '${json['descripcionProducto'] ?? ''}',
    cantidad: _asDouble(json['cantidad']),
    importeCentavos: (_asDouble(json['importe']) * 100).round(),
    fecha: DateTime.tryParse('${json['fecha'] ?? ''}') ?? DateTime.now(),
    servicioId: _asInt(json['idServicio']),
    presentacion: '${json['presentacionProducto'] ?? ''}',
  );

  Map<String, dynamic> toJson() => {
    'claveProducto': productoId,
    'descripcionProducto': descripcion,
    'cantidad': cantidad,
    'importe': importeCentavos / 100,
    'fecha': fecha.toIso8601String(),
    'idServicio': servicioId,
    'presentacionProducto': presentacion,
  };

  static int _asInt(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  static double _asDouble(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

String formatoMoneda(int centavos) =>
    '\$${(centavos / 100).toStringAsFixed(2)}';
