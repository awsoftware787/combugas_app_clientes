import 'dart:convert';

import 'item_pedido.dart';

final class CreateOrderRequest {
  const CreateOrderRequest({
    required this.direccionId,
    required this.clienteId,
    required this.telefonoId,
    required this.metodoPagoId,
    required this.detalles,
    this.observaciones,
  });

  final int direccionId;
  final int clienteId;
  final int telefonoId;
  final int metodoPagoId;
  final List<CreateOrderDetail> detalles;
  final String? observaciones;

  factory CreateOrderRequest.fromItems({
    required int direccionId,
    required int clienteId,
    required int telefonoId,
    required int metodoPagoId,
    required List<ItemPedido> items,
    String? observaciones,
  }) => CreateOrderRequest(
    direccionId: direccionId,
    clienteId: clienteId,
    telefonoId: telefonoId,
    metodoPagoId: metodoPagoId,
    detalles: items.map(CreateOrderDetail.fromItem).toList(growable: false),
    observaciones:
        observaciones?.trim().isEmpty ?? true ? null : observaciones!.trim(),
  );

  String get detalleJson =>
      jsonEncode(detalles.map((item) => item.toJson()).toList());

  Map<String, Object?> get soapParameters => {
    '_intIdDireccion': direccionId,
    '_intIdCliente': clienteId,
    '_intIdTelefono': telefonoId,
    '_intIdMetodoPago': metodoPagoId,
    '_strDetallePedido': detalleJson,
    '_observacionesPedido': observaciones,
  };
}

final class CreateOrderDetail {
  const CreateOrderDetail({
    required this.clave,
    required this.cantidad,
    required this.importe,
  });

  final int clave;
  final double cantidad;
  final double importe;

  factory CreateOrderDetail.fromItem(ItemPedido item) => CreateOrderDetail(
    clave: item.productoId,
    cantidad: double.parse(item.cantidad.toStringAsFixed(2)),
    importe: double.parse((item.importeCentavos / 100).toStringAsFixed(2)),
  );

  Map<String, Object> toJson() => {
    'clave': clave,
    'cantidad': cantidad,
    'importe': importe,
  };
}

final class CreateOrderResult {
  const CreateOrderResult({required this.pedidoId, this.mensaje = ''});
  final int pedidoId;
  final String mensaje;
}

final class TiempoFase {
  const TiempoFase({
    required this.id,
    required this.tiempo,
    required this.unidad,
  });
  final int id;
  final String tiempo;
  final String unidad;
  String get descripcion => '$tiempo $unidad'.trim();
}
