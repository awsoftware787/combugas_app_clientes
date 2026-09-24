import 'producto.dart';

final class ItemPedido {
  const ItemPedido({
    required this.productoId,
    required this.descripcion,
    required this.cantidad,
    required this.importeCentavos,
    required this.fecha,
    required this.servicioId,
    required this.presentacion,
    this.tipoProductoId,
    this.tipoProducto,
    this.urlIcono,
  });

  final int productoId;
  final String descripcion;
  final double cantidad;
  final int importeCentavos;
  final DateTime fecha;
  final int servicioId;
  final String presentacion;
  final int? tipoProductoId;
  final String? tipoProducto;
  final String? urlIcono;

  bool get esCroqueta => servicioId == ServicioIds.croquetas;

  ItemPedido copyWith({
    String? descripcion,
    double? cantidad,
    int? importeCentavos,
    DateTime? fecha,
    String? presentacion,
    int? tipoProductoId,
    String? tipoProducto,
    String? urlIcono,
  }) => ItemPedido(
    productoId: productoId,
    descripcion: descripcion ?? this.descripcion,
    cantidad: cantidad ?? this.cantidad,
    importeCentavos: importeCentavos ?? this.importeCentavos,
    fecha: fecha ?? this.fecha,
    servicioId: servicioId,
    presentacion: presentacion ?? this.presentacion,
    tipoProductoId: tipoProductoId ?? this.tipoProductoId,
    tipoProducto: tipoProducto ?? this.tipoProducto,
    urlIcono: urlIcono ?? this.urlIcono,
  );

  factory ItemPedido.fromJson(Map<String, dynamic> json) => ItemPedido(
    productoId: _asInt(json['claveProducto']),
    descripcion: '${json['descripcionProducto'] ?? ''}',
    cantidad: _asDouble(json['cantidad']),
    importeCentavos: (_asDouble(json['importe']) * 100).round(),
    fecha: DateTime.tryParse('${json['fecha'] ?? ''}') ?? DateTime.now(),
    servicioId: _asInt(json['idServicio']),
    presentacion: '${json['presentacionProducto'] ?? ''}',
    tipoProductoId: _asNullableInt(json['idTipoProducto']),
    tipoProducto: _asNullableText(json['tipoProducto']),
    urlIcono: _asNullableText(json['urlIcono']),
  );

  Map<String, dynamic> toJson() => {
    'claveProducto': productoId,
    'descripcionProducto': descripcion,
    'cantidad': cantidad,
    'importe': importeCentavos / 100,
    'fecha': fecha.toIso8601String(),
    'idServicio': servicioId,
    'presentacionProducto': presentacion,
    'idTipoProducto': tipoProductoId,
    'tipoProducto': tipoProducto,
    'urlIcono': urlIcono,
  };

  static int _asInt(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  static double _asDouble(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  static int? _asNullableInt(Object? value) =>
      value == null
          ? null
          : value is num
          ? value.toInt()
          : int.tryParse('$value');
  static String? _asNullableText(Object? value) {
    final text = value == null ? '' : '$value'.trim();
    return text.isEmpty || text == 'null' ? null : text;
  }
}

String formatoMoneda(int centavos) =>
    '\$${(centavos / 100).toStringAsFixed(2)}';
